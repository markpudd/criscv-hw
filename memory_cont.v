/*  Super simple (and slightly rubbish) SRAM MMU,  there is massive optimzations that could be done for this:-
			*  Caching would substabtialy speed the whole thing up 
			*  Bigger reads - Currently using 16-bit memory - the built in Cyclone memory can deliver 256 bits at a time
			*  Use Cyclone dual port to optimizes instruction vs data
			*  Don't allow byte addresses (unless the byte commands)
			*  Add pre-fetch (likely next read is last read (pc) +4
*/



module memory_cont(input clk,
						 input reset,
						 input wire [31:0] address,
						 input wire rw_req,
						 input wire  rw,
						 input wire[31:0] write_data,
						 input wire[1:0] size,
						 output wire[31:0] read_data,
						 output data_valid);
			

	reg reading;

	localparam MEMORY_DELAY = 3'd2; 

	reg [31:0] i_address;
	reg i_rw;
	reg [1:0] i_size;
	reg [31:0] i_write_data;
	reg [31:0] i_read_data;
	reg [31:0] i_read_data_f;
	reg i_data_valid=0;
	
	reg [1:0] be= 2'b11;	
	reg [11:0]  br_address= 12'h00000000;
	//wire [11:0]  ir_address;
	//wire [31:0]  sd_address;
	reg [15:0] br_data;
	reg	  		 br_rden= 1'b0;
	reg	  		 br_wren= 1'b0;
	//wire    	  	 sd_rden;
	//wire	  		 sd_wren;
	//wire	    	 bi_rden;
	//wire	  		 bi_wren;
	wire [15:0] br_q;
	//wire [15:0] bi_q;
	//wire [15:0] bsd_q;
	
	
	ram ram(.address(br_address),
				.byteena(be),
				.clock(clk),
				.data(br_data),
				//.rden(br_rden),
				.wren(br_wren),
				.q(br_q));


				
				
	reg [2:0] mc_state=3'h0;
	reg [2:0] delay=0;

	assign data_valid = i_data_valid;
	assign read_data = i_read_data_f;		
	/*
	assign bi_rden = address<32'h2FFFF ?  br_rden :1'b0;
	assign sd_rden = address>=32'h2FFFF ?  br_rden :1'b0;


	assign bi_wren = address<32'h2FFFF ?  br_wren :1'b0;
	assign sd_wren = address>=32'h2FFFF ?  br_wren :1'b0;

		
	assign br_q = address<32'h2FFFF ?  bi_q :bsd_q ;		
	
	
	assign ir_address = br_address[11:0];
	assign sd_address = br_address[30:0] - 31'h1FFFF;*/
	
	always @ ( posedge clk) begin
		if(~reset)
		begin
			i_data_valid <=0;
			i_size <= 0;
			mc_state<=3'h0;
			br_rden <= 1'b0;	
			br_wren <= 1'b0;	
			br_address <= 12'h00000000;
			be<= 2'b11;
			delay <=0;
		end
		else
		if(address[31]==0 && address < 32'h10000 )
		case(mc_state)
			3'h0: begin   // 
					i_data_valid <= 0;
					if(rw_req)
						begin
										
							i_address <= address;					
							// read first word
							i_size <= size;
							be = 2'b11;
							br_rden <= 1'b1;
							br_wren <= 1'b0;	
							i_read_data <= 32'h00000000;
							br_address <= address[12:1];
							case(size) 
								2'h2: begin
											mc_state = 3'h1;
											i_write_data <= {write_data[7:0],
												 write_data[15:8],
												 write_data[23:16],
												 write_data[31:24]};										
										end
								2'h1: begin
											mc_state = 3'h3;
											i_write_data <= { write_data[7:0],
												 write_data[15:8]};	
										end
								2'h0: begin
											mc_state = 3'h5;
											i_write_data <=  write_data[7:0];
										end	
							endcase	
							delay<=MEMORY_DELAY;
						end
					end
			3'h1: begin 	 //  pt1
						delay <= delay-3'h1;
						if(delay==0)
							begin
							if(rw==0)
							begin
								if(i_address[0] == 1'b0)
									i_read_data[31:16] <= br_q;
								else
									i_read_data[31:24] <= br_q[7:0];
								br_address <= br_address+12'h1;
								mc_state <= 3'h3;
							end
							else
							begin
								if(i_address[0] == 1'b0)
								begin
									br_data[15:0] <= i_write_data[31:16];
									be = 2'b11;
								end
								else
									begin
									br_data[7:0] <= i_write_data[31:24];
									be = 2'b01;
								end
								br_rden <= 1'b0;
								br_wren <= 1'b1;	
								mc_state <= 3'h2;
							end
							delay <=MEMORY_DELAY;
						end
					end
			3'h2: begin
						delay <= delay-3'h1;
						if(delay==0)
							begin
						br_address <= br_address+12'h1;
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
							br_address <= br_address+12'h1;
						end
						else
						begin
							if(i_address[0] == 1'b0)
							begin
								br_data[15:0] <= i_write_data[15:0];
								be = 2'b11;
								mc_state <= 3'h6;		
							end
							else
							begin
								br_data[15:0] <= i_write_data[23:8];
								be = 2'b11;
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
						br_address <= br_address+12'h1;
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
							begin
								br_data[15:8] <= i_write_data[7:0];	
								be = 2'b10;
							end
							else
							begin
								br_data[7:0] <= i_write_data[7:0];
								be = 2'b01;
							end
							br_rden <= 0;
							br_wren <= 1;						
						end
						mc_state = 3'h6;
						delay <=MEMORY_DELAY;
						end
					end
			3'h6: begin 	 // read pt1 and sort out endianess
						if(i_size == 2'h2)
							i_read_data_f <= {i_read_data[7:0],
													i_read_data[15:8],
													i_read_data[23:16],
													i_read_data[31:24]};
						if(i_size == 2'h1)
							i_read_data_f <= {i_read_data[7:0],
													i_read_data[15:8]};					
						if(i_size == 2'h0)
							i_read_data_f <= {24'h0,i_read_data[7:0]};					
						i_data_valid <= 1;
						br_rden <= 1'b0;
						br_wren <= 1'b0;	
						be = 2'b11;
						mc_state = 3'h7;
					end		
			3'h7: begin 	 // read pt1
						i_data_valid <= 0;
						mc_state = 3'h0;
					end	
		endcase
	end
	
	
		 

endmodule