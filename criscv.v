module criscv(input  mclk,
					input  reset,
					output wire port,
					output reg led);



   reg [2:0] funct3;
   reg modbit;
	reg  alu_clk = 1'b0;

   reg [31:0] imm_i;
	reg [31:0] imm_b;
	reg [31:0] imm_j;
	reg [31:0] imm_s;
	reg [31:0] imm_u;
   reg [6:0] opcode;
   reg [31:0] rs1;
   reg [31:0] rs2;
	reg [5:0] rd_index;
	
   wire  [31:0] rd;

	
	reg [31:0]  pc= 32'h0000008c;
	reg [31:0]  inst;
	reg [31:0]  regs [31:0] ;
	reg [2:0] state =0;

	wire mem_rec;
	wire alu_comp;
	
	//wire [31:0] mem_address_w;
	reg [31:0] mem_address;
	
//	wire mem_rw_req_w;
	reg mem_rw_req;
//	wire mem_rw_w;
	reg mem_rw;
	
	
	reg [31:0] mem_write_data;
		
	//wire [1:0] mem_size_w;
	reg [1:0] mem_size;
	wire [31:0] mem_read_data;
	

	//wire cclk;
	
	
	//clock clock (
	//				.inclk0(mclk),
	//				.c0(cclk));
	
	alu  alui(.clk(alu_clk), 
				 .funct3(funct3), 
				 .modbit(modbit), 
				 .imm(imm_i), 
				 .opcode(opcode), 
				 .rs1(rs1), 
				 .rs2(rs2),
				 .rd(rd),
				 .comp(alu_comp));
	
	 memory_cont memory_cont( 	.clk(mclk),
										.reset(reset),
										.port(port),
										.address(mem_address),
										.rw_req(mem_rw_req),
										.rw(mem_rw),
										.write_data(mem_write_data),
										.size(mem_size),
										.read_data(mem_read_data),
										.data_valid(mem_rec));
										
										
										
	initial
	begin
		state=0;
		alu_clk =0;
	end
	
		/*					imm_i =  $signed(mem_read_data[31:20]);
						rd1_index = mem_read_data[19:15];
						rd2_index = mem_read_data[24:20];
	
						rd_index = mem_read_data[11:7];
						funct3 = mem_read_data[14:12];
						modbit =mem_read_data[30];
						imm_s =  $signed({mem_read_data[31:25], mem_read_data[11:7]});
						imm_b = $signed({mem_read_data[31] ,mem_read_data[7],mem_read_data[30:25],mem_read_data[11:8], 1'b0});
						imm_j = $signed({mem_read_data[31],  mem_read_data[19:12], mem_read_data[20], mem_read_data[30:21] ,1'b0 });
						imm_u = mem_read_data & 32'hFFFFF000;
					opcode = mem_read_data[6:0];
	
	

	always @(*)
	begin

			if(mem_read_data[19:15] == 0)
				rs1 <= 0;
			else
				rs1 <= regs[mem_read_data[19:15]];
			if(mem_read_data[24:20] == 0)
				rs2 <= 0;
			else						
				rs2 <= regs[mem_read_data[24:20]];
	end
	*/
	
	
	always @ ( posedge mclk) begin
	if(~reset)
	begin
		pc <= 32'h00000000;
		regs[2] <= 32'h00001FFC;  //Stack intialization
		state <=0;
		alu_clk <=0;
		led <= 0;
	end
	else
	begin
	led <= 1;
	case(state)
		3'h0: begin   // Fetch instruction
				if(alu_clk && rd_index !=0)
					regs[rd_index] <= rd;
				alu_clk <=0;
				mem_address <= pc;  // set mem address
				mem_rw <= 0;        // read
				mem_rw_req <= 1;  //request
				mem_size <= 2;
				state <= 3'h1;
				end
				
		3'h1: begin  // decode  - This could be optimied to continual assignment but this keeps timing simple
					if(mem_rec)
					begin
						imm_i =  $signed(mem_read_data[31:20]);

		
						rd_index = mem_read_data[11:7];
						funct3 = mem_read_data[14:12];
						modbit =mem_read_data[30];
						imm_s =  $signed({mem_read_data[31:25], mem_read_data[11:7]});
						imm_b = $signed({mem_read_data[31] ,mem_read_data[7],mem_read_data[30:25],mem_read_data[11:8], 1'b0});
						imm_j = $signed({mem_read_data[31],  mem_read_data[19:12], mem_read_data[20], mem_read_data[30:21] ,1'b0 });
						imm_u = mem_read_data & 32'hFFFFF000;
						opcode = mem_read_data[6:0];
						if(mem_read_data[19:15] == 0)
							rs1 <= 0;
						else
							rs1 <= regs[mem_read_data[19:15]];
						if(mem_read_data[24:20] == 0)
							rs2 <= 0;
						else						
							rs2 <= regs[mem_read_data[24:20]];
						mem_rw_req<= 0;
						state <= 3'h2;
					end
				end
		3'h2: begin   // EXECUTE
					casex (opcode)
						 7'b0x10011 :  // ALU
							begin
								alu_clk <=1; //ALU WAIT
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
												mem_address <= rs1+imm_i ;				         // LBU
												mem_size <= 0;
												end
									3'b101 : begin
												mem_address <= rs1+imm_i ; 						// LHU
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
					7'b1110011 :  // ECALL/EBREAK
							begin
							end								
					7'b0001111 :  // FENCE
							begin
							end								
							
					endcase

				end
		3'h3: begin   // Load Complete
				if(mem_rec)
				begin
					regs[rd_index] <= mem_read_data;
					mem_rw_req<= 0;
					pc <= pc + 4;
					state <= 3'h0;
				end	  
			end
		 3'h4: begin   // save Complete
		 		if(mem_rec)
				begin
						pc <= pc + 4;
						mem_rw_req<= 0;
						state <= 3'h0;	  
				end	
				end	
		endcase
		end
	end
endmodule
