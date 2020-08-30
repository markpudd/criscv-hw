
module sdram(
				input	  clk,
				input reset,
				input	[32:0]  address,
				input wire rw_req,
				input wire  rw,
				input wire[31:0] write_data,
				input wire[1:0] size,
				output wire[31:0] read_data,
				output data_valid,
				

				
				
				input  mclk,
				inout [15:0] dram_dq,
				output wire [12:0] dram_addr,
				output wire [1:0] dram_dqm,
				output wire dram_cke,
				output wire dram_we_n,
				output wire dram_cas_n,
				output wire dram_ras_n,
				output wire dram_cs_n,
				output wire dram_ba0,
				output wire dram_ba1);

	localparam START_DELAY= 32'd500000; 		
//localparam START_DELAY= 24'd2; 		
	localparam CAS_DELAY= 32'd1; 					
	localparam BANK_DELAY= 32'd1; 	
		localparam WRITE_DELAY= 32'd6; 					

	reg [3:0] state;				

	reg [31:0] delay;
	reg rcount;

	reg [31:0] din;
	reg [15:0] dout;
	reg	[32:0]  i_address;
   reg [12:0] i_dram_addr;
   reg [1:0] i_dram_dqm;
	
	reg [1:0] i_size;
	reg i_dram_cke;
	reg i_dram_we_n;
	reg i_dram_cas_n;
	reg i_dram_ras_n;
	reg i_dram_cs_n;
	reg i_dram_ba0;
	reg i_dram_ba1;
	reg i_data_valid=0;
	reg wh=0;
	reg rf=0;
		
	assign dram_addr=i_dram_addr;
	assign dram_cke=i_dram_cke;
	assign dram_we_n = i_dram_we_n;
	assign dram_cas_n =i_dram_cas_n;
	assign dram_ras_n = i_dram_ras_n;
	assign dram_cs_n = i_dram_cs_n;
	assign dram_ba0 = i_dram_ba0;
	assign dram_ba1 = i_dram_ba1;
	
	reg i_wren;
	
	assign dram_dqm = i_dram_dqm; //2'b00; //be^2'b11;
	assign dram_dq = ~i_wren ? dout : 16'bZ;
	assign read_data = din;
	
	assign data_valid = i_data_valid;


	always @ (posedge mclk) begin

		if(~reset)
		begin
			rcount<=0;
			i_dram_cs_n <=0;
			i_dram_cke <= 1'b0;
			i_dram_cs_n <= 1'b0;
			i_dram_ras_n <= 1'b1;
			i_dram_cas_n <= 1'b1;
			i_dram_we_n <= 1'b1;
			i_data_valid <=0;
			wh <= 0;
			rf <=0;
			state<=4'h0;
			delay<=START_DELAY;
		end
		else
			rcount <= rcount^1'b1;
			case(state)
				4'h0: begin  //Start delay
					i_dram_cke <= 1'b0;
					if(delay == 31'h0)
					begin
						state<=4'h1;
					end
					else
						delay <= delay -31'h1;
					end
				4'h1: begin  //send nop
						i_dram_cke <= 1'b1;
						i_dram_cs_n <= 1'b0;
						i_dram_ras_n <= 1'b1;
						i_dram_cas_n <= 1'b1;	
						i_dram_we_n <= 1'b1;
						state<=4'h2;
						 end
				4'h2: begin  //PRECHARGE ALL BANKS
						i_dram_cke <= 1'b1;
						i_dram_cs_n <= 1'b0;
						i_dram_ras_n <= 1'b0;
						i_dram_cas_n <= 1'b1;
						i_dram_we_n <= 1'b0;
						i_dram_addr[10] <= 1'b1;
						i_dram_ba0 <= 1'b0;
						i_dram_ba1 <= 1'b0;
						state<=4'h3;
						delay<=16384;
						 end
				4'h3: begin   //AUTO REFRESH 1
						if(delay==0)
							state<=4'h5;
						else
						begin
						if(delay[0] ==0)
							begin
								i_dram_cke <= 1'b1; // AUTO REFRESH
								i_dram_cs_n <= 1'b0;
								i_dram_ras_n <= 1'b0;
								i_dram_cas_n <= 1'b0;
								i_dram_we_n <= 1'b1;
							end
							else
							begin
								i_dram_cs_n <= 1'b0;  //NOP
								i_dram_ras_n <= 1'b1;
								i_dram_cas_n <= 1'b1;
								i_dram_we_n <= 1'b1;
							end
							delay <= delay - 32'b1;
						end
						end
				4'h5: begin  //Load Mode register
							i_dram_cs_n <= 1'b0;  //
							i_dram_ras_n <= 1'b0;
							i_dram_cas_n <= 1'b0;
							i_dram_we_n <= 1'b0;
							i_dram_addr[0] <= 1'b0;  // Just get 1 to start with
							i_dram_addr[1] <= 1'b0;
							i_dram_addr[2] <= 1'b0;
							i_dram_addr[3] <= 1'b0;
							i_dram_addr[4] <= 1'b0;
							i_dram_addr[5] <= 1'b1;
							i_dram_addr[6] <= 1'b0;
							i_dram_addr[7] <= 1'b0;
							i_dram_addr[8] <= 1'b0;
							i_dram_addr[9] <= 1'b1;   // Write Burst
							i_dram_addr[10] <= 1'b0;
							i_dram_addr[11] <= 1'b0;
							i_dram_addr[12] <= 1'b0;
							i_dram_ba0 <= 1'b0;
							i_dram_ba1 <= 1'b0;
								delay<=5;
							state<=4'hD;
					   end
					4'hD: begin  //Load Mode register
						if(delay ==0)
							begin
								state<=4'h6;
							end
							else
							begin
								i_dram_cs_n <= 1'b0;  //NOP
								i_dram_ras_n <= 1'b1;
								i_dram_cas_n <= 1'b1;
								i_dram_we_n <= 1'b1;
								delay <= delay - 32'b1;
							end

					   end
				4'h6: begin  //Open Bank
					i_data_valid <=0;
						if((rw_req==1 || wh==1) && delay==0 && address>= 32'h2FFFF && ~address[31] && rf==0 )
						begin
								if(wh==0) 
								begin
									i_address = (address-32'h2FFFF);
									i_size <= size;
								end
								else 
									i_address=i_address+2;
								
								i_address = (address-32'h2FFFF);
								i_dram_cs_n <= 1'b0;  //OPEN BANK/ROW
								i_dram_ras_n <= 1'b0;
								i_dram_cas_n <= 1'b1;
								i_dram_we_n <= 1'b1;
								i_dram_addr[12:0]<= 12'h0; //address[12:0];
								i_dram_ba0 <= 1'b0; //address[13];
								i_dram_ba1 <=  1'b0; //address[14];
								if(size == 2'b0 && rw==1'b1) 
									i_dram_dqm <= {~address[0], address[0]};		

								else
								i_dram_dqm <= 2'b00;
								delay<=BANK_DELAY;
								state<=4'h7;
						end
						else
						begin
							if(delay > 0)
								delay <= delay -31'h1;
							else
								delay<=0;
							if(delay == 0)
							begin
							if(rf ==0)
							begin
									i_dram_cke <= 1'b1; // AUTO REFRESH
									i_dram_cs_n <= 1'b0;
									i_dram_ras_n <= 1'b0;
									i_dram_cas_n <= 1'b0;
									i_dram_we_n <= 1'b1;
									rf<=1;
								end
								else
								begin
									i_dram_cs_n <= 1'b0;  //NOP
									i_dram_ras_n <= 1'b1;
									i_dram_cas_n <= 1'b1;
									i_dram_we_n <= 1'b1;
									rf<=0;
									
									delay<=4;
								end
							 end
							 end
						end
						
				4'h7: begin  // Wait for Req	
						if(delay ==0)
						begin
							i_dram_addr[9:0] =i_address[10:1];  // column
							i_dram_addr[10] <= 1'b1;
							i_dram_ba0 <=  1'b0; //address[13];
							i_dram_ba1 <=  1'b0; //address[14];
							if(rw==0)   
							begin
								i_dram_cs_n <= 1'b0;  //READ
								i_dram_ras_n <= 1'b1;
								i_dram_cas_n <= 1'b0;
								i_dram_we_n <= 1'b1;

								delay<=CAS_DELAY;
								state<=4'h8;
							end
							else
							begin
								i_dram_cs_n <= 1'b0;  //WRITE
								i_dram_ras_n <= 1'b1;
								i_dram_cas_n <= 1'b0;
								i_dram_we_n <= 1'b0;
								i_wren <=1;
								case(i_size)
									2'h2: begin
											if(wh)
											begin
												dout <= {write_data[7:0],write_data[15:8]};
												wh<=0;
											end
											else
											begin
												dout <= {write_data[23:16],write_data[31:24]};
												wh<=1;
											end
											end
									2'h1: begin
												dout <= {write_data[7:0],write_data[15:8]};
											end
									2'h0: begin
												if(~i_address[0])
												begin
													dout[15:8] <= write_data[7:0];
												end
												else
												begin
													dout[7:0] <= write_data[7:0];
												end
											end
									endcase
								delay<=CAS_DELAY;
								state<=4'hC;
							end
						end
						else
						begin
								i_dram_cs_n <= 1'b0;  //NOP
								i_dram_ras_n <= 1'b1;
								i_dram_cas_n <= 1'b1;
								i_dram_we_n <= 1'b1;
								delay <= delay -31'h1;
						end
					end

				4'h8: begin  //READ WORD
						
						i_dram_cs_n <= 1'b0;  //NOP
						i_dram_ras_n <= 1'b1;
						i_dram_cas_n <= 1'b1;
						i_dram_we_n <= 1'b1;
						i_dram_dqm <= 2'b0;
						if(delay == 31'h0)
						begin
						case(i_size)
							2'h2: begin
									if(wh)
									begin
										din[15:0] <= {dram_dq[7:0],dram_dq[15:8]};
										i_data_valid <=1;
										wh<=0;
									end
									else
									begin
										din[31:16] <= {dram_dq[7:0],dram_dq[15:8]};
										wh<=1;
									end
									end
							2'h1: begin
										din[15:0] <= {dram_dq[7:0],dram_dq[15:8]};
										i_data_valid <=1;
									end
							2'h0: begin
										if(~i_address[0])
										begin
											din[7:0] <= dram_dq[15:8];
										end
										else
										begin
											din[7:0] <= dram_dq[7:0];
										end
										i_data_valid <=1;
									end
								endcase
							delay<=31'd1;
							state<=4'h6;
						end
						else
					    	delay <= delay -31'h1;
						end
				4'hC: begin  //WRITE FINISH
						i_dram_cs_n <= 1'b0;  //NOP
						i_dram_ras_n <= 1'b1;
						i_dram_cas_n <= 1'b1;
						i_dram_we_n <= 1'b1;
						i_dram_dqm <= 2'b0;
						if(delay == 31'h0)
						begin
						i_wren <=0;
						if(~wh)
							i_data_valid <=1;
						delay<=31'd3;
						state<=4'h6;
						end
								else
					    	delay <= delay -31'h1;
						 end				 
			endcase
	end

endmodule



