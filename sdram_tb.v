`timescale 1ns / 1ps

module sdram_testbench;


	reg clk;
	reg reset;


	reg [11:0]  address;
	reg [1:0]  be;
	reg [15:0]  write_data;
	reg rden;
	reg wren;
	wire [15:0]  read_data;
	wire dram_dq;
	wire [12:0] dram_addr;
	wire [1:0] dram_dqm;
	wire dram_cke;
	wire dram_we_n;
	wire dram_cas_n;
	wire dram_ras_n;
	wire dram_cs_n;
	wire dram_ba0;
	wire dram_ba1;

				
				
   sdram sdram(.clk(clk),
			.reset(reset),
			.address(address),
			.be(be),
			.write_data(write_data),
			.rden(rden),
			.wren(wren),
			.read_data(read_data),	
			.dram_dq(dram_dq),
			.dram_addr(dram_addr),
			.dram_dqm(dram_dqm),
			.dram_cke(dram_cke),
			.dram_we_n(dram_we_n),
			.dram_cas_n(dram_cas_n),
			.dram_ras_n(dram_ras_n),
			.dram_cs_n(dram_cs_n),
			.dram_ba0(dram_ba0),
			.dram_ba1(dram_ba1));
			
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
		

		
		#2
		clk = 1;
		#2
		clk=0;
		
		#30
		address = 32'h000000c0;
		be = 2'b11;
		rden <= 1'b1;
		wren <= 1'b0;	
	end

	always 
      #2  clk =  ! clk; 
		
endmodule
