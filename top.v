module top(input  mclk,
			  input  reset,
				output wire port,
				output wire sout,
				output wire led);

					
	wire [31:0] address;	
	wire rw_req;	
	wire rw;				
	wire [31:0] write_data;
	wire [1:0] size;
	
	wire [31:0] read_data;
	wire [31:0] mread_data;
	wire [31:0] pread_data;
	wire  rec;
	wire drec;
	wire prec;
	
	
	
	//reg pport;
	assign rec = drec | prec;
	
	//assign port = pport;
	
	assign read_data = ~address[31]? mread_data : pread_data;
	
	
	criscv cpu(.mclk(mclk),
				  .reset(reset),
				  .led(led),
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
										.sout(sout)	);
										

	 
	// PLL to speed up 
	//wire cclk;
	//clock clock (
	//				.inclk0(mclk),
	//				.c0(cclk));

endmodule
	 
	 