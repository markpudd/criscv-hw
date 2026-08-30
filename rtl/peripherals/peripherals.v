	// Peripheral Memory map Glue
	module peripherals(input clk,
						 input reset,				 
						 input wire [31:0] address,
						 input wire rw_req,
						 input wire  rw,
						 input wire[31:0] write_data,
						 input wire[1:0] size,
						 output wire [31:0] read_data,
						 output wire prec,
						 output reg [3:0]port,
						 output sout,
						 input sin);
	
	wire  uart_busy;
	
	reg  ss;
	wire  rec_valid;
	reg  [7:0] sdata;
	//reg  [2:0] tdelay;
	
	reg [31:0] i_read_data;
	wire [7:0] rec_data;
	reg i_prec;
	reg i_port;
	
//	uart  uart(clk, sout,reset,ss,sdata,uart_busy);	
	
	uart uart( .sclk(clk),
				  .dout(sout),
				  .reset(reset),
				   .ss(ss),
				   .data(sdata),
					.busy(uart_busy),
					.rec_data(rec_data),
					.rec_valid(rec_valid),
					.din(sin),
					.rr(rr));
	
	assign read_data = i_read_data;
	assign prec = i_prec;
	
	reg rr;
	reg [1:0] pstate=3'h0;
//	reg [2:0] delay=0;
	
	always @ (posedge clk) begin
		if(~reset)
		begin
		pstate=3'h0;
			i_read_data <=0;
			i_prec <= 0;
		//	port <= 0;
		//	tdelay<=0;
		end
		else
			case(pstate)
				2'b00: begin
						 if(rw_req)
							 begin
								if(address == 32'hffffff00) 
								begin
									port <= write_data[3:0];
									i_prec <=1;
									pstate <= 2'b01;
								end
								if(address == 32'hffffff01) 
								begin
									sdata <= write_data[7:0];
									ss<=1;
									i_prec <=1;
									pstate <= 2'b01;
								end
								if(address == 32'hffffff02) 
								begin
									i_read_data <= {30'h00000000,rec_valid,uart_busy};
									i_prec <=1;
									pstate <= 2'b01;
								end
								if(address == 32'hffffff03) 
								begin
									i_read_data <= {24'h000000,rec_data};
									i_prec <=1;
									if(rec_valid)
										rr=1;
									pstate <= 2'b10;
								end
							 end else
									rr=0;   //  clear read signal
						 end
				2'b01: begin
							i_prec <=0;
							ss<=0;
							pstate <= 2'b00;
						 end
				2'b10: begin
							i_prec <=0;
							pstate <= 2'b00;
						 end
			endcase
	end
					
endmodule				
					

