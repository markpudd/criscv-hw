module criscv(input  mclk,
					input  reset,
					input  cpu_reset,
					output reg led,
					output reg crash,
					output reg [31:0] mem_address,
					output reg mem_rw_req,
				   output reg mem_rw,
				   output reg [31:0] mem_write_data,
					output reg [1:0] mem_size,
					input [31:0] mem_read_data,
					input mem_rec);


	localparam START_DELAY= 32'd501000; 		
	
	
	//  Machine CSR offsets
	localparam MTS_BASE     = 12'h300;
	localparam MSTATUS  	 	= 12'h0; 		
	localparam MISA      	= 12'h1; 		
	localparam MEDELEG   	= 12'h2; 		
	localparam MIDELEG   	= 12'h3; 		
	localparam MIE   			= 12'h4; 		
	localparam MTVEC   		= 12'h5; 		
	localparam MCOUNTEREN   = 12'h6; 		

	
	localparam MTH_BASE     = 12'h340;
	localparam MSCRATCH  	= 12'h0; 		
	localparam MEPC      	= 12'h1; 		
	localparam MCAUSE   		= 12'h2; 		
	localparam MTVAL   		= 12'h3; 		
	localparam MIP   			= 12'h4; 		

	
	reg [31:0] delay;
	reg [31:0] instruction;

	
	reg  alu_req = 1'b0;
	
   wire [2:0] funct3;
   wire modbit;
   wire [31:0] imm_i;
	wire [31:0] imm_b;
	wire [31:0] imm_j;
	wire [31:0] imm_s;
	wire [31:0] imm_u;
   wire [6:0] opcode;
   wire [31:0] rs1;
   wire [31:0] rs2;
	wire [5:0] rd_index;
	wire [4:0] uimm;
	wire [11:0] csr;	
	
	assign imm_i =  $signed(instruction[31:20]);
	assign imm_s =  $signed({instruction[31:25], instruction[11:7]});
	assign imm_b = $signed({instruction[31] ,instruction[7],instruction[30:25],instruction[11:8], 1'b0});
	assign imm_j = $signed({instruction[31],  instruction[19:12], instruction[20], instruction[30:21] ,1'b0 });
	assign imm_u = instruction & 32'hFFFFF000;
	assign opcode = instruction[6:0];
	assign rd_index = instruction[11:7];
	assign funct3 = instruction[14:12];
	assign modbit =instruction[30];
	assign uimm = instruction[19:15];
	assign csr = instruction[31:20];
	assign rs1 = (instruction[19:15] == 0) ? 0 : regs[instruction[19:15]];
	assign rs2 = (instruction[24:20] == 0) ? 0 : regs[instruction[24:20]];	

	// L1  read  only instruction cache - 
	// No self modding code - but to penalty compared to no cache on miss
	wire  [2:0] cache_offset;
	wire  [3:0] cache_set;
	wire [21:0] cache_tag; 
	
	assign cache_offset = pc[4:2];
	assign cache_set = pc[8:5];
	assign cache_tag = pc[30:9];
	
	reg [21:0] l1_cache_lu [0:15];
	reg [31:0] l1_cache [0:15][0:7];
	
	reg [2:0] cacheline_counter;

   wire  [31:0] rd;

	
	reg [3:0] cache_clear_counter;
	reg [31:0]  pc= 32'h000000c0;
//	reg [31:0]  inst;
	reg [31:0]  regs [31:0] ;
	reg [3:0]   state =0;

	
//	reg [31:0] l1_cache [0:64];
	//reg [23:0]


	wire [31:0] mpx_csr;
	reg [31:0] mpx_reg;

	// CSR Registers to allow for traps, exception and interupts
	reg [31:0]  machine_trap_setup_regs [7:0] ;
	reg [31:0]  machine_trap_handling_regs [5:0] ;
	reg [63:0] mcycle;
	reg [63:0] minstret;
	
	/*
function csr_func;
		input [12:0] csr_i;
		begin
	//	csr_func = 0;
		case(csr_i[11:8])
			4'h3: begin
						 if(csr_i[7:4] == 4'h0) csr_func = machine_trap_setup_regs[csr_i[3:0]];
						 if(csr_i[7:4] == 4'h3) csr_func = machine_trap_handling_regs[csr_i[3:0]];
			      end
			4'hb: begin
						 if(csr_i[7:0] == 4'h0) csr_func = mcycle[31:0];
						 if(csr_i[7:0] == 4'h2) csr_func = minstret[31:0];
						 if(csr_i[7:0] == 4'h80) csr_func = mcycle[63:32];
						 if(csr_i[7:0] == 4'h82) csr_func = minstret[63:32];
			      end	
		endcase
		end
endfunction

assign mpx_csr =csr_func(csr);
*/


assign mpx_csr = (csr[11:8] == 4'h3) ?
						 (csr[7:4] == 4'h0) ?  machine_trap_setup_regs[csr[3:0]] :
						 (csr[7:4] == 4'h3) ?  machine_trap_handling_regs[csr[3:0]] :
						 0 :
						 (csr[11:8] == 4'hb) ?
							(csr[7:4] == 4'h0) ?  mcycle[31:0] :
							(csr[7:4] == 4'h2) ?   minstret[31:0] :
							(csr[7:4] == 4'h80) ?    mcycle[63:32] :
							(csr[7:4] == 4'h82) ?  minstret[63:32] :
						 0
						 : 0;
	

		
	wire alu_comp;



	
	alu  alui(.clk(mclk), 
				 .req(alu_req),
				 .reset(reset),
				 .funct3(funct3), 
				 .modbit(modbit), 
				 .imm(imm_i), 
				 .opcode(opcode), 
				 .rs1(rs1), 
				 .rs2(rs2),
				 .rd(rd),
				 .comp(alu_comp));
	

																										
	
	initial
	begin
		state<=0;
		alu_req <=0;
	end
	
	// Begin code to monitor PC, if it doesn't change crash
/*	reg [31:0]old_pc;
	reg [9:0] count;
	localparam CRASH_DELAY= 10'd256; 	
	
	always @ ( posedge mclk) begin
		if(~reset)
		begin
			count<=CRASH_DELAY;
			crash<=0;
		end
		else
		begin
		if(delay == 0)
			if(old_pc != pc) 
			begin
				old_pc <= pc;
				count<=CRASH_DELAY;
				crash<=0;
			end
			else
			begin
				if(count==0 )
					crash<=0;
				else
					count<=count-10'd1;
			end
		end
	end
	*/
	
	
	always @ ( posedge mclk) begin
	if(~reset)
	begin
		pc <=32'h0;
		crash <= 0;
		mcycle<=0;
		minstret<=0;
		cache_clear_counter <= 0;
	//	pc <= 32'h000002a0;
	//	pc <= 32'h000000C0;
		regs[2] <= 32'h00BFFFFC;  //Stack intialization - To be replaced with bootloader
	//	regs[3] <= 32'h00001800;  //gp intialization - To be replaced with bootloader
		state <=5;
		alu_req <=0;
		led <= 0;
		delay <= START_DELAY;
	end
	else
	if(~cpu_reset)    // reset but don't clear memeory
	begin
		pc <=32'h0;
		regs[2] <= 32'h00BFFFFC;  //Stack intialization - To be replaced with bootloader
		state <=6;
		alu_req <=0;
		led <= 0;
	end
	else
	begin
	led <= 1;
	mcycle<=mcycle+63'b1;
	case(state)
		4'h5:  begin   // Start delay (SDRAM)
				if(delay == 0)
					state <= 3'h6;
				else
				begin
					l1_cache_lu[cache_clear_counter] = 21'h1fffff;
					cache_clear_counter <=cache_clear_counter-4'b1;
					delay = delay-1;
					end
				end
		4'h6: begin // Fetch entry address
				mem_address <= 32'h00000018; 
				mem_rw <= 0;        // read
				mem_rw_req <= 1;
				state <= 3'h7;
				end
		4'h7: begin 
					if(mem_rec)
					begin
						pc <=mem_read_data; 
						mem_rw_req <= 0;
						state <= 3'h0;
					end
				end		
		4'h0: begin   // Fetch instruction
				if(alu_req && !alu_comp)
					state <= 3'h0;
				else
				begin
				if(alu_req &&  rd_index !=0)
					regs[rd_index] <= rd;
				alu_req <=0;
					mem_size <= 2;
					mem_rw <= 0; 
				// Check cache - don't use cache if tag 0
				if(cache_tag == l1_cache_lu[cache_set])
				begin
					instruction <= l1_cache[cache_set][cache_offset];
					mem_rw_req<= 0;
					state <= 3'h2;
				end
				else
				begin
					mem_address <= pc & ~32'h1F;  // set mem address
					cacheline_counter = 32'h7;
					mem_rw_req <= 1;  //request
			   	state <= 3'h1;
				end
				end
				end
				
		4'h1: begin  // load cache line - assume instruction on 4 byte boundry
					if(mem_rec)
					begin
						// Write to cache
						crash <= 1;
						l1_cache[cache_set][mem_address[4:2]] <= mem_read_data;
						l1_cache_lu[cache_set] <= cache_tag;
						instruction <= mem_read_data;
						//  TODO This is dodge as  cache counter is ambiguos
						if(cacheline_counter != 0) begin
							cacheline_counter = cacheline_counter-1;
							mem_address <= mem_address+4;
							mem_rw_req<= 1;
							state <= 3'h1;
						end
						else
						begin
							// read from cache
							mem_rw_req<= 0;
							state <= 3'h0;
						end
					end
				end
		4'h2: begin   // EXECUTE   -  TODO combine with decode and drop a cycle!
				minstret<=minstret+63'b1;
		//					if(!mem_rec)
			//	begin
					casex (opcode)
						 7'b0x10011 :  // ALU
							begin
								alu_req <=1; //ALU WAIT
								pc <= pc + 4;
								state <= 3'h0; 
							end
						7'b0000011 :  // LOAD  - From here on in we are pretty much running instrutions
										  //         Would be nice to have seperat module but requires 
										  //         memory multiplexing complexity
							begin
								case (funct3)
									3'b000 : begin
												mem_address <= rs1+$signed(imm_i); // LB
												mem_size <= 0;
												end
									3'b001 :  begin
												mem_address <= rs1+$signed(imm_i);  // LH
												mem_size <= 1;
												end
									3'b010 : begin
												mem_address <= rs1+$signed(imm_i);  // LW
												mem_size <= 2;
												end
									3'b100 : begin
												mem_address <= rs1+$signed(imm_i) ;				         // LBU
												mem_size <= 0;
												end
									3'b101 : begin
												mem_address <= rs1+$signed(imm_i) ; 						// LHU
												mem_size <= 1;
												end										
									// TODO Default excpetion
								endcase		
								mem_rw <= 0;
								mem_rw_req<= 1;
								state <= 3'h3;  //MEM  READ WAIT
							end
						7'b0100011 :  // STORE
							begin
								case (funct3)
									3'b000 : begin                                        // SB
												mem_size <= 0;
												end
									3'b001 :  begin                                       // SH
												mem_size <= 1;
												end
									3'b010 : begin                                        // SW
												mem_size <= 2;
												end							
									// TODO Default excpetion
								endcase
								mem_address <= rs1+$signed(imm_s);  
								mem_write_data <= rs2;			
								mem_rw <= 1;
								mem_rw_req<= 1;
								state <= 3'h4;  //MEM  WRITE WAIT
							end
						7'b1100011 :  // BRANCH
							begin
								case (funct3)
										3'b000 : begin                                        // BEQ
													if(rs1 == rs2) 
														pc <= pc+imm_b;
													else
														pc <= pc+4;
													end
										3'b001 : begin                                        // BNE
													if(rs1 != rs2) 
														pc <= pc+imm_b;
													else
														pc <= pc+4;
													end
										3'b100 : begin                                        // BLT
													if($signed(rs1) < $signed(rs2)) 
														pc <= pc+imm_b;
													else
														pc <= pc+4;
													end
										3'b101 : begin                                        // BGE
													if($signed(rs1) >= $signed(rs2)) 
														pc <= pc+imm_b;
													else
														pc <= pc+4;
													end
										3'b110 : begin                                        // BLTU
													if(rs1 < rs2) 
														pc <= pc+imm_b;
													else
														pc <= pc+4;
												end	
										3'b111 : begin                                        // BGEU
													if(rs1 >= rs2) 
														pc <= pc+imm_b;
													else
														pc <= pc+4;
												end	
										// TODO Default excpetion
								endcase
								state <= 3'h0;
							end
					7'b1101111 :  // JAL
							begin
								 if(rd_index !=0)
									regs[rd_index] <= pc+4;
								 pc <= pc+$signed(imm_j);
								 state <= 3'h0;
							end
					7'b1100111 :  // JALR
							begin
								if(rd_index !=0)
									 regs[rd_index] <= pc+4;
								 pc <= rs1+$signed(imm_i);
								 state <= 3'h0;
							end
					7'b0110111 :  // LUI
							begin
								if(rd_index !=0)
									 regs[rd_index] <= imm_u;
								 pc <= pc + 4;
								 state <= 3'h0;								 
							end
					7'b0010111 :  // AUIPC
							begin
								if(rd_index !=0)
									regs[rd_index] = pc+ imm_u;
								pc <= pc + 4;
							   state <= 3'h0;	
							end
					7'b0001111 :  // FENCE
							begin
							end									
					7'b1110011 :  // SYSYTEM
							begin
								case (funct3)
										3'b000 : begin     // ECALL/EBREAK
													if(imm_i == 0)
													begin
															machine_trap_handling_regs[MEPC] <= pc+4;
															mem_address <= machine_trap_setup_regs[MTVEC] + (11*4); // LW
															mem_size <= 2;
															mem_rw <= 0;
															mem_rw_req<= 1;
															state <= 4'h8;	
														// MPIE -set
														// MEPC - code 11
													end
													else
													begin   // (USM)RET
														// TODO check it MRET
														pc <= machine_trap_handling_regs[MEPC];
													//	pc <= pc+4;
														state <= 3'h0;
													end
													end
										3'b001 : begin  // CSRRW
													//read CRS
													if(rd_index != 0) regs[rd_index] = mpx_csr;	
													//  This is a bit rubish
													if(csr[11:8] == 4'h3)
													begin
														if(csr[7:4] == 4'h0) machine_trap_setup_regs[csr[3:0]]  <= rs1;
														if(csr[7:4] == 4'h3) machine_trap_handling_regs[csr[3:0]]  <= rs1;
													end
													pc <= pc+4;
													state <= 3'h0;
													end
										3'b010 : begin  // CSRRS - TODO Fix
													regs[rd_index] = mpx_csr | rs1;
													pc <= pc+4;
													state <= 3'h0;
													end
										3'b011 : begin  // CSRRC - TODO Fix
													regs[rd_index] = mpx_csr & ~rs1;
													pc <= pc+4;		
													state <= 3'h0;
													end
										3'b101 : begin  // CSRRWI
													if(rd_index != 0) regs[rd_index] = mpx_csr;	
													//  This is a bit rubish
													if(csr[11:8] == 4'h3)
													begin
														if(csr[7:4] == 4'h0) machine_trap_setup_regs[csr[3:0]]  <= uimm;
														if(csr[7:4] == 4'h3) machine_trap_handling_regs[csr[3:0]]  <= uimm;
													end
													pc <= pc+4;
													state <= 3'h0;
													end
										3'b110 : begin  // CSRRSI - TODO Fix
													regs[rd_index] = mpx_csr | uimm;
													pc <= pc+4;
													state <= 3'h0;
													end
										3'b111 : begin  // CSRRCI - TODO Fix
													regs[rd_index] = mpx_csr & ~uimm;
													pc <= pc+4;
													state <= 3'h0;
													end
								endcase
							end								
							
					endcase
		//		end
				end
		4'h3: begin   // Load Complete
				if(mem_rec)
				begin
					if(funct3== 3'b000)
						regs[rd_index] <= $signed(mem_read_data[7:0]);
					else if(funct3== 3'b001)
						regs[rd_index] <= $signed(mem_read_data[15:0]);
					else if(funct3== 3'b100)
						regs[rd_index] <= {24'h0,mem_read_data[7:0]};
					else if(funct3== 3'b101)
						regs[rd_index] <= {16'h0,mem_read_data[15:0]};
					else
						regs[rd_index] <= mem_read_data;
					mem_rw_req<= 0;
					pc <= pc + 4;
					state <= 3'h0;
				end	  
			end
		 4'h4: begin   // save Complete
		 		if(mem_rec)
				begin
						pc <= pc + 4;
						mem_rw_req<= 0;
						state <= 3'h0;	  
				end	
				end	
		 4'h8: begin   // Ecall mem fetched Complete
		 		if(mem_rec)
				begin
						pc <= mem_read_data;
						mem_rw_req<= 0;
						state <= 3'h0;	  
				end	
				end	
								
		endcase
		end
	end
endmodule