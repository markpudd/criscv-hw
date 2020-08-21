`timescale 1ns / 1ps

module uart_testbench;


	reg sclk;
  wire dout;
	reg reset;
	reg  ss;
	reg  [7:0] data;

	uart  uart(sclk, dout,reset,ss,data);

	initial
		begin
		$dumpfile ("uart.vcd");

	
		reset =0;
		#2
		sclk=0;
		#2
		sclk = 1;
		#2
		sclk=0;
		reset =1;
	#200
		ss =1;
		data = 8'h23;
		#4
		ss=0;
		

	//	$finish;
	end

	
	 always 
    #2  sclk =  ! sclk; 
	 
endmodule
