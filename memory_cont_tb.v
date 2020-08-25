`timescale 1ns / 1ps

module memory_cont_testbench;


	reg clk;
	reg reset;

		
	reg [31:0] address;	
	reg rw_req;	
	reg rw;				
	reg [31:0] write_data;
	reg [1:0] size;
	

	wire [31:0] mread_data;
	wire drec;


	memory_cont memory_cont( 	.clk(clk),
										.reset(reset),
										.address(address),
										.rw_req(rw_req),
										.rw(rw),
										.write_data(write_data),
										.size(size),
										.read_data(mread_data),
										.data_valid(drec));
	initial
		begin
		$dumpfile ("mem.vcd");


		reset =0;
		#2
		clk=0;
		#2
		clk = 1;
		#2
		clk=0;
		reset =1;
		#2
		clk = 1;
		#2
		clk=0;
		
		address = 32'h000000c0;
		rw_req = 1'b1;	
		rw = 1'b0;	
		size = 2'b0;
		
		#2
		clk = 1;
		#2
		clk=0;
		
		
		#2
		clk = 1;
		#2
		clk=0;

	end

	always 
      #2  clk =  ! clk; 
		
endmodule
