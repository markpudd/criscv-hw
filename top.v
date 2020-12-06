module top(input  mclk,	
			  input  reset,
			  input  cpu_reset,
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
				output wire per_led,
				output [3:0]r,
				output [3:0]g,
				output [3:0]b,
				output vsync,
				output hsync);

					
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
//	wire drec;
	wire sdrec;
	wire prec;
	wire dram_clkp;
	wire vclkint;

	wire cache_clk;
	wire cpu_clk;
	wire vclk;
	
	wire [31:0] sd_address;
	wire [15:0] sd_read_data;
	wire [15:0] sd_write_data;
	
	wire sd_rw;
	wire sd_bursting;
	wire sd_ce;
	
	wire [31:0] sd_address_mmu;
	wire [15:0] sd_read_data_mmu;
	wire [15:0] sd_write_data_mmu;
	wire sd_rw_mmu;
	wire sd_rw_req_mmu;
	wire sd_bursting_mmu;
	wire sd_ce_mmu;

	wire [31:0] sd_address_v;
	wire [15:0] sd_read_data_v;
	wire sd_rw_req_v;
	wire sd_bursting_v;
	wire sd_burst_len;
	wire sd_burst_len_mmu;
	wire sd_burst_len_v;

	wire sd_busy_v;
	wire mmu_busy;
	
	wire vga_cmd_done;
	wire vga_cmd_write;
	
		// PLL to clock mem correctly
	mem_clock memclk (
					.inclk0(mclk),
					.c0(cache_clk),
					.c1(cpu_clk));
	
	video_clock video_clock(
					.inclk0(mclk),
					.c0(vclk));

	
	dram_clk dram_clock(
					.inclk0(mclk),
					.c0(dram_clk),
					.c1(dram_clk_2));
					
	// Bus Arb - TODO move into SDRAM where it should be
	reg ram_arb;		
	reg sd_rw_req;
	
	// Video has priority
	always @ (posedge cache_clk) begin
		if(~reset)
		begin
			ram_arb<=1'b0;
			sd_rw_req<=1'b0;
		end
		else
		begin
			if(!sd_bursting && !sd_rw_req) begin
				if(sd_rw_req_v ==1) begin
					ram_arb<=1'b0;
					sd_rw_req<=1'b1;
				end
				else if(sd_rw_req_mmu ==1) begin
					ram_arb<=1'b1;
					sd_rw_req<=1'b1;
				end	
			end
			else
				sd_rw_req<=ram_arb ? sd_rw_req_mmu :sd_rw_req_v;
		end
	end

	
	assign sd_address = ram_arb ? sd_address_mmu :sd_address_v;
	assign sd_read_data_mmu =sd_read_data;
	assign sd_read_data_v =sd_read_data;
	
	assign sd_write_data = sd_write_data_mmu;
	assign sd_rw = ram_arb ? sd_rw_mmu : 1'b0;
	assign sd_bursting_mmu = sd_bursting & ram_arb;
	assign sd_bursting_v = sd_bursting & !ram_arb;
	assign sd_ce = 1'b1;
	assign sd_burst_len = ram_arb ? sd_burst_len_mmu :sd_burst_len_v;

			
	assign read_data = ~address[31]? dread_data : pread_data;
	
	assign rec = ~address[31]?  sdrec: 
					~address[15] ?
				 vga_cmd_done : prec;
										
	assign vga_cmd_write =address[31] & rw_req & rw & ~address[15];
	
	assign mem_led =sdrec;

	assign per_led =prec;
					

					
	vga vga(        .clk(dram_clk_2),	
					    .vclk(vclk),
						 .reset(reset),
						 .address(sd_address_v),
						 .rw_req(sd_rw_req_v),
						 .read_data(sd_read_data_v),
						 .burst_len(sd_burst_len_v),
						 .data_available(sd_bursting_v),
						 .cmd_byte(write_data[7:0]),
						 .cmd_address(address[9:0]),
						 .cmd_write(vga_cmd_write),
						 .cmd_done(vga_cmd_done),
						 .sd_busy(sd_busy_v),
						 .r(r),
						 .g(g),
						 .b(b),
						 .vsync(vsync),
						 .hsync(hsync));					
					
					
	criscv cpu(.mclk(cpu_clk),
				  .reset(reset),
				  .cpu_reset(cpu_reset),

				  .led(led),
				  .crash(crash),
				  .mem_address(address),
				  .mem_rw_req(rw_req),
				  .mem_rw(rw),
				  .mem_write_data(write_data),
				  .mem_size(size),
				  .mem_read_data(read_data),
				  .mem_rec(rec));
				  
		  


		mmu mmu(.clk(cache_clk),
						.mclk(dram_clk_2),
						.reset(reset),
						.address(address),
						.rw_req(rw_req),
						.rw(rw),
						.write_data(write_data),
						.size(size),
						.read_data(dread_data),
						.data_valid(sdrec),
						.busy(mmu_busy),
						
						.sd_ce(sd_ce_mmu),
						.sd_address(sd_address_mmu),
						.sd_rw_req(sd_rw_req_mmu),
						.sd_rw(sd_rw_mmu),
						.sd_write_data(sd_write_data_mmu),
						.sd_read_data(sd_read_data_mmu),
						.sd_burst_len(sd_burst_len_mmu),
						.sd_data_bursting(sd_bursting_mmu)
								
						);
				  

	
	 peripherals	 peripherals(.clk(cpu_clk),
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

		sdramburst sdramburst( .clk(dram_clk_2),
								.ce(sd_ce),
								 .reset(reset),
								 .address(sd_address),
								 .rw_req(sd_rw_req),
								 .rw(sd_rw),
								 .write_data(sd_write_data),
								 .read_data(sd_read_data),
								 .burst_len(sd_burst_len),
								 .data_bursting(sd_bursting),
					
								 
		
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
										
/*
	 	vga vga( .vclk(vclk),		 
					.reset(reset),	
					.r(r),
					.g(g),
					.b(b),
					.vsync(vsync),
					.hsync(hsync));
					*/
	// PLL to speed up 
	//wire cclk;
	//clock clock (
	//				.inclk0(mclk),
	//				.c0(cclk));

endmodule
	 
	 