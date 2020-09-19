module top(input  mclk,
			  input  reset,
				output wire [3:0]port,
				output wire crash,
				output wire sout,
				output wire led,
				input sin,
				output wire  dram_clk,
				inout [15:0] dram_dq,
				output wire [12:0] dram_addr,
				output wire [1:0] dram_dqm,
				output wire dram_cke,
				output wire dram_we_n,
				output wire dram_cas_n,
				output wire dram_ras_n,
				output wire dram_cs_n,
				output wire dram_ba0,
				output wire dram_ba1,
				output wire mem_led,
				output wire per_led);

					
	wire [31:0] address;	
	wire rw_req;	
	wire rw;				
	wire [31:0] write_data;
	wire [1:0] size;
	
	wire [31:0] read_data;
	wire [31:0] mread_data;
	wire [31:0] pread_data;
	wire [31:0] dread_data;
	wire  rec;
	wire drec;
	wire sdrec;
	wire prec;
	wire dram_clkp;
		// PLL to clock mem correctly
	mem_clock memclk (
					.inclk0(mclk),
					.c0(dram_clk));
	
//	assign dram_clk = mclk;
	
	
	//reg pport;
//	assign rec = drec | sdrec |sdrec;
	//assign rec = drec | prec; // |sdrec;
	
	//assign port = pport;
	
	assign read_data = ~address[31]? (address<32'h10000 ?  mread_data : dread_data)
										  :  pread_data;
	
	assign rec = ~address[31]? (address<32'h10000 ?  drec : sdrec)
										  :  prec;
	//assign read_data = ~address[31]? mread_data :   pread_data;
			
	assign mem_led =drec |sdrec;
	//assign sd_led = sdrec;
	assign per_led =prec;
					
	criscv cpu(.mclk(mclk),
				  .reset(reset),
				  .led(led),
				  .crash(crash),
				  .mem_address(address),
				  .mem_rw_req(rw_req),
				  .mem_rw(rw),
				  .mem_write_data(write_data),
				  .mem_size(size),
				  .mem_read_data(read_data),
				  .mem_rec(rec));
				  
		  
				  
	
	memory_cont memory_cont( 	.clk(mclk),
										.reset(reset),
										.address(address),
										.rw_req(rw_req),
										.rw(rw),
										.write_data(write_data),
										.size(size),
										.read_data(mread_data),
										.data_valid(drec));
															
	 
	 sdramnew sdramnew(.clk(mclk),
										.reset(reset),
										.address(address),
										.rw_req(rw_req),
										.rw(rw),
										.write_data(write_data),
										.size(size),
										.read_data(dread_data),
										.data_valid(sdrec),
					
					.mclk(dram_clk),
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
	
	 peripherals	 peripherals(.clk(mclk),
										.reset(reset),				 
										.address(address),
										.rw_req(rw_req),
										.rw(rw),
										.write_data(write_data),
										.size(size),
										.read_data(pread_data),
										.prec(prec),
										.port(port),
										.sout(sout),
									   .sin(sin));
										

	 
	// PLL to speed up 
	//wire cclk;
	//clock clock (
	//				.inclk0(mclk),
	//				.c0(cclk));

endmodule
	 
	 