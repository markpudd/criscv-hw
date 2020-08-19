`timescale 1ns / 1ps

module criscv_testbench;


	reg clk;
	reg reset;
	wire out;
	integer i;
	
	criscv criscv(clk,reset,out);
	
	initial
		begin
		$dumpfile ("criscv.vcd");
	
		reset =0;
		#2
		clk=0;
		#2
		clk = 1;
		#2
		clk=0;
		reset =1;
		
		//$finish;
	end
	
   always 
      #2  clk =  ! clk; 
endmodule
