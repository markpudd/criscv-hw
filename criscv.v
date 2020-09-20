module criscv(input  mclk,
					input  reset,
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
	reg [31:0] delay;
	
	
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
	/*
	reg led;
	 reg [31:0] mem_address;
	 reg mem_rw_req;
	 reg  mem_rw;
	 reg[31:0] mem_write_data;
	 reg[1:0] mem_size;
	*/
	
	reg [31:0]  pc= 32'h000000c0;
	reg [31:0]  inst;
	reg [31:0]  regs [31:0] ;
	reg [2:0]   state =0;


	wire alu_comp;

	/*
	wire mem_rec;
	reg [31:0] mem_address;
	reg mem_rw_req;
	reg mem_rw;
	reg [31:0] mem_write_data;
	reg [1:0] mem_size;
	wire [31:0] mem_read_data;
		 memory_cont memory_cont( 	.clk(mclk),
										.reset(reset),
										.port(port),
									   .sout(sout),
										.address(mem_address),
										.rw_req(mem_rw_req),
										.rw(mem_rw),
										.write_data(mem_write_data),
										.size(mem_size),
										.read_data(mem_read_data),
										.data_valid(mem_rec));*/


	
	alu  alui(.clk(alu_clk), 
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
		state=0;
		alu_clk =0;
	end
	
	// Begin code to monitor PC, if it doesn't change crash
	reg [31:0]old_pc;
	reg [9:0] count;
	localparam CRASH_DELAY= 10'd512; 	
	
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
					crash<=1;
				else
					count<=count-10'd1;
			end
		end
	end
	
	
	
	always @ ( posedge mclk) begin
	if(~reset)
	begin
		pc <=0;
	//	pc <= 32'h000002a0;
	//	pc <= 32'h000000C0;
		regs[2] <= 32'h00001FFC;  //Stack intialization - To be replaced with bootloader
	//	regs[3] <= 32'h00001800;  //gp intialization - To be replaced with bootloader
		state <=5;
		alu_clk <=0;
		led <= 0;
		delay <= START_DELAY;
	end
	else
	begin
	led <= 1;
	case(state)
		3'h5:  begin   // Start delay (SDRAM)
				if(delay == 0)
					state <= 3'h6;
				else
					delay = delay-1;
				end
		3'h6: begin // Fetch entry address
				mem_address <= 32'h00000018; 
				mem_rw <= 0;        // read
				mem_rw_req <= 1;
				state <= 3'h7;
				end
		3'h7: begin 
					if(mem_rec)
					begin
						pc <=mem_read_data; 
						mem_rw_req <= 0;
						state <= 3'h0;
					end
				end		
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