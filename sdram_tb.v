`timescale 1ns / 1ns

module sdram_testbench;


	reg clk;
	reg mclk;
	reg reset;


	reg [31:0]  address;
	reg rw_req;	
	reg rw;				
	reg [31:0] write_data;
	reg [1:0] size;
	
	wire [15:0]  read_data;
	
	wire [15:0] dram_dq;
	wire [12:0] dram_addr;
	wire [1:0] dram_dqm;
	wire dram_cke;
	wire dram_we_n;
	wire dram_cas_n;
	wire dram_ras_n;
	wire dram_cs_n;
	wire dram_ba0;
	wire dram_ba1;

				
				
   sdramnew  sdramnew(.clk(clk),
			.reset(reset),
			.address(address),
			.rw_req(rw_req),
			.rw(rw),
			.write_data(write_data),
			.size(size),
			.read_data(read_data),
			.data_valid(data_valid),
			.mclk(mclk),
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
	
	 IS42VM16400K rmsim(.dq(dram_dq), 
						.addr(dram_addr), 
						.ba({dram_ba0,dram_ba1}), 
						.clk(mclk), 
						.cke(dram_cke), 
						.csb(dram_cs_n), 
						.rasb(dram_ras_n), 
						.casb(dram_cas_n), 
						.web(dram_we_n), 
						.dqm(dram_dqm));
	
		initial
		begin
			mclk = 0;
			forever begin

				#10 mclk = ~mclk;
			end
		end
	
		initial
		begin
			clk = 0;
			#17
		forever begin
			#10 clk = ~clk;
		end
		end
		
	initial
		begin


		reset =0;

		#100
		reset =1;
		#102000

		address = 32'h00030000;
		rw_req = 1'b1;	
		rw = 1'b1;	
		size = 2'b0;
		write_data = 32'h23;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030001;
		rw_req = 1'b1;	
		rw = 1'b1;	
		size = 2'b0;
		write_data = 32'h24;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030002;
		rw_req = 1'b1;	
		rw = 1'b1;	
		size = 2'b0;
		write_data = 32'h25;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030003;
		rw_req = 1'b1;	
		rw = 1'b1;	
		size = 2'b0;
		write_data = 32'h26;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030004;
		rw_req = 1'b1;	
		rw = 1'b1;	
		size = 2'b0;
		write_data = 32'h27;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030005;
		rw_req = 1'b1;	
		rw = 1'b1;	
		size = 2'b0;
		write_data = 32'h28;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030006;
		rw_req = 1'b1;	
		rw = 1'b1;	
		size = 2'b0;
		write_data = 32'h29;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030007;
		rw_req = 1'b1;	
		rw = 1'b1;	
		size = 2'b0;
		write_data = 32'h30;
		#200
		rw_req = 1'b0;
		#300
		
		
		
		
		
		address = 32'h00030000;
		rw_req = 1'b1;	
		rw = 1'b0;	
		size = 2'b0;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030001;
		rw_req = 1'b1;	
		rw = 1'b0;	
		size = 2'b0;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030002;
		rw_req = 1'b1;	
		rw = 1'b0;	
		size = 2'b0;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030003;
		rw_req = 1'b1;	
		rw = 1'b0;	
		size = 2'b0;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030004;
		rw_req = 1'b1;	
		rw = 1'b0;	
		size = 2'b0;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030005;
		rw_req = 1'b1;	
		rw = 1'b0;	
		size = 2'b0;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030006;
		rw_req = 1'b1;	
		rw = 1'b0;	
		size = 2'b0;
		#200
		rw_req = 1'b0;
		#300
		address = 32'h00030007;
		rw_req = 1'b1;	
		rw = 1'b0;	
		size = 2'b0;
		#200
		rw_req = 1'b0;
	

	end

		
endmodule
