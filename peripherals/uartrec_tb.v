`timescale 1ns / 1ps

module uartrec_testbench;


	reg clk;
   wire dout;
   wire busy;
	reg reset;
	reg  ss;
	reg  [7:0] data;
	wire [7:0] rec_data;
	wire rec_valid;
	reg  din;
	reg rr;
					
					
	uart  uart(clk, dout,reset,ss,data,busy,rec_data,rec_valid, din,rr);


	
	initial
		begin
			clk = 0;
		forever begin
			#10 clk = ~clk;
		end
	end
	
	initial
		begin
		$dumpfile ("uart.vcd");

		din = 1;
		reset =0;
		#200000
		reset =1;
		#100000
		
		// idle
		din = 1;
		#104000
		
		
		//Start bit
		din = 0;
		#104000
		
		
		din = 0;
		#104000
		din = 0;
		#104000
		din = 0;
		#104000
		din = 1;
		#104000
		din = 0;
		#104000
		din = 0;
		#104000
		din = 1;
		#104000
		din = 0;
		#104000
		din = 1;

		
		
		
		
		
		
	//	$finish;
	end

	 
endmodule