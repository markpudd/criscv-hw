module uart(input wire sclk,
				   output wire dout,
				   input reset,
				   input wire ss,
				   input wire [7:0] data);

	localparam UART_TIME_DELAY = 13'h1458; 				
					
	reg [2:0] in_pos;
	reg [7:0] i_data;
	reg i_dout;
	reg sending;
	reg [13:0] delay;
	reg [2:0] state;

	assign dout = i_dout;
	
	always @(posedge sclk)
	begin
		if(~reset)
		begin
			in_pos<=3'b000;
			state<=3'h0;
			sending <= 1'b0;
			i_dout <= 1'b1;
		end
		else
		if(ss || sending)
		begin
			case(state)
			3'h0: begin
					sending <= 1'b1;
					i_data <= data;
					in_pos<=3'b000;
					i_dout <= 1'b1;
					delay <= UART_TIME_DELAY;
					state = 3'h1;
					end
			3'h1: begin     // Start bit
					if(delay == 13'h0)
					begin
						delay <= UART_TIME_DELAY;
						state = 3'h2;
					end
					else
						delay <= delay -13'h1;
					i_dout <= 1'b0;
					end
					
			3'h2: begin     // Data bits
									i_dout <= i_data[in_pos];
					if(delay == 13'h0)
					begin

						if(in_pos == 3'b111)
						begin
							in_pos<=3'b000;
							delay <= UART_TIME_DELAY;
							state = 3'h3;
						end
						else
						begin
							in_pos<=in_pos+1'b1;
							delay <= UART_TIME_DELAY;
						end
					end
					else
						delay <= delay -13'h1;

					end
			3'h3: begin     // End bit
								
					if(delay == 13'h0)
					begin
						i_dout <= 1'b1;
						delay <= UART_TIME_DELAY;
						state = 3'h5;
					end
					else
						delay <= delay -13'h1;
					end
			3'h4: begin   //finish
					if(delay == 13'h0)
					begin
						i_dout <= 1'b0;
						delay <= UART_TIME_DELAY;
						state = 3'h5;
					end
					else
						delay <= delay -13'h1;
					end
			3'h5: begin   //finish
	
					if(delay == 13'h0)
					begin
						sending <= 1'b0;
						i_dout <= 1'b1;
						state = 3'h0;
					end
					else
						delay <= delay -13'h1;
					end
				endcase
			end
		end
					
	
endmodule