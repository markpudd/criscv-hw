/*  Super simple (and slightly rubbish) SRAM MMU,  there is massive optimzations that could be done for this:-
			*  Caching would substabtialy speed the whole thing up 
			*  Bigger reads - Currently using 16-bit memory - the built in Cyclone memory can deliver 256 bits at a time
			*  Use Cyclone dual port to optimizes instruction vs data
			*  Don't allow byte addresses (unless the byte commands)
			*  Add pre-fetch (likely next read is last read (pc) +4
*/

module memory_cont(input clk,
						 input reset,
						 output port,
						 input wire [31:0] address,
						 input wire rw_req,
						 input wire  rw,
						 input wire[31:0] write_data,
						 input wire[1:0] size,
						 output wire[31:0] read_data,
						 output data_valid);
			

	reg reading;

	localparam MEMORY_DELAY = 2; 

	reg [31:0] i_address;
	reg i_rw;
	reg [1:0] i_size;
	reg [31:0] i_read_data;
	reg i_data_valid=0;
	reg i_port;
	
	
	reg	[8:0]  br_address;
	reg	[15:0] br_data;
	reg	  		 br_rden;
	reg	  		 br_wren;
	wire	[15:0] br_q;
	
	
	bootram bootram(br_address,clk,br_data,br_rden,br_wren,br_q);

	reg [2:0] mc_state=0;
	reg [2:0] delay=0;

	always @ ( posedge clk) begin
		if(~reset)
		begin
			i_data_valid <=0;
			mc_state<=0;
			delay <=0;
		end
		else
		begin
		case(mc_state)
			3'h0: begin   // 
					i_data_valid <= 0;
					if(rw_req)
						begin
							i_address <= address;					
							if(rw)
							begin
								i_port <= write_data[0];
								delay<=0;
								mc_state = 3'h6;
							end
							else
							begin
							// read first word
							i_size <= size;
							br_rden <= 1'b1;
							br_wren <= 1'b0;	
							br_address <= address[8:1];
							case(i_size) 
								2'h2: begin
											mc_state = 3'h1;
										end
								2'h1: begin
											mc_state = 3'h3;
										end
								2'h0: begin
											mc_state = 3'h5;
										end									
							endcase	
							delay<=MEMORY_DELAY;
						end
						end
					end
			3'h1: begin 	 //  pt1
						delay <= delay-1;
						if(delay==0)
							begin
							if(rw==0)
							begin
								if(i_address[0] == 1'b0)
									i_read_data[31:16] <= br_q;
								else
									i_read_data[31:24] <= br_q[7:0];
								br_address <= br_address+1;
								mc_state <= 3'h3;
							end
							else
							begin
								if(i_address[0] == 1'b0)
									br_data[15:0] <= write_data[31:16];
								else
									br_data[7:0] <= write_data[31:24];
								br_rden <= 1'b0;
								br_wren <= 1'b1;	
								mc_state <= 3'h2;
							end
							delay <=MEMORY_DELAY;
						end
					end
			3'h2: begin
						delay <= delay-1;
						if(delay==0)
							begin
						br_address <= br_address+1;
						br_rden <= 1'b1;
						br_wren <= 1'b0;	
						mc_state <= 3'h3;
						delay <=MEMORY_DELAY;
						end
					end
			3'h3: begin 	 //   TODO FIX for 16-bit on byte offset
												delay <= delay-3'h1;
						if(delay==0)
							begin
						if(rw==0)
						begin
							if(i_address[0] == 1'b0)
							begin
								i_read_data[15:0] <= br_q;
								mc_state = 3'h6;
							end
							else
							begin
								i_read_data[23:8] <= br_q;
								mc_state = 3'h5;
							end
							br_address <= br_address+1;
						end
						else
						begin
							if(i_address[0] == 1'b0)
							begin
								br_data[15:0] <= write_data[15:0];
								mc_state <= 3'h6;		
							end
							else
							begin
								br_data[15:0] <= write_data[23:8];
							end
							br_rden <= 1'b0;
							br_wren <= 1'b1;				
						
						end
						delay <=MEMORY_DELAY;
						end
					end
			3'h4: begin 	 // read pt1
						delay <= delay-3'h1;
						if(delay==0)
							begin
						br_address <= br_address+1;
						br_rden <= 1'b1;
						br_wren <= 1'b0;	
						mc_state <= 3'h5;
						delay <=MEMORY_DELAY;
						end
					end

			3'h5: begin 	 // read pt1
												delay <= delay-3'h1;
						if(delay==0)
							begin
						if(rw==0)
							if(i_address[0] == 1'b0)
							begin
								i_read_data[7:0] <= br_q[15:8];
							end
							else
							begin
								i_read_data[7:0] <= br_q[7:0];
							end		
						else
						begin
							if(i_address[0] == 1'b0)
								br_data[15:8] <= write_data[7:0];	
							else
								br_data[7:0] <= write_data[7:0];
							br_rden <= 0;
							br_wren <= 1;						
						end
						mc_state = 3'h6;
						delay <=MEMORY_DELAY;
						end
					end
			3'h6: begin 	 // read pt1
						i_data_valid <= 1;
						br_rden <= 1'b0;
						br_wren <= 1'b0;	
						mc_state = 3'h7;
					end		
			3'h7: begin 	 // read pt1
						i_data_valid <= 0;
						mc_state = 3'h0;
					end	
		endcase
		end
	end
	
	assign data_valid = i_data_valid;
	assign  port = i_port;
	assign read_data = i_read_data;			 

endmodule