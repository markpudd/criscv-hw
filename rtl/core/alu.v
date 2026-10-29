module alu(input wire clk,
			  input wire div_req,
			  input wire reset,
			  input wire [2:0] funct3,
			  input wire modbit,
			  input wire [31:0] imm,
			  input wire [6:0] opcode,
			  input wire [31:0] rs1,
			  input wire [31:0] rs2,
			  output wire [31:0] rd,
			  output wire busy);
	
	
	
	localparam 	IDLE = 2'd0,
				   DIV_WAIT = 2'd1,
					DIV_COMP = 2'd2,
					DONE = 2'd3;
		
	localparam 	DIV_DELAY = 4'd7;	
	
	
	reg [5:0] div_counter;
	
	
	reg [31:0] d_rd;	
		
	assign rd = div_req ? d_rd :srd;

	reg [1:0] nState;
	reg [1:0] cState;
	
	reg [31:0] denom;
	reg [31:0] numer;
	wire [31:0] quotient;
	wire [31:0] remain;
	wire [31:0] uquotient;
	wire [31:0] uremain;
	
	assign busy =(cState != DONE);

		
		
  divider divider (.clock (clk),
						.denom(denom),
						.numer(numer),
						.quotient(quotient),
						.remain(remain));
	
  udivider udivider (.clock (clk),
						.denom(denom),
						.numer(numer),
						.quotient(uquotient),
						.remain(uremain));
		

	// RV32I	
	
	wire is_imm = (opcode == 7'b0010011);   // OP-IMM
	wire rv32m_inst = (opcode == 7'b0110011  & imm[5]) ;   // OP-IMM
	wire is_reg = (opcode == 7'b0110011);   // OP
   
	wire alu_imm    = is_imm;
	wire rv32i_inst = is_imm |  (is_reg & ~imm[5])  ;  // imm[5]==funct7[0]==RV32M - we really need to fix this
    

	wire a_signed = (funct3 == 3'b001) || (funct3 == 3'b010); // MULH, MULHSU
	wire b_signed = (funct3 == 3'b001);                        // MULH only

	wire signed [32:0] a = {a_signed & rs1[31], rs1};
	wire signed [32:0] b = {b_signed & rs2[31], rs2};
	wire signed [65:0] prod = a * b;

	reg [31:0] srd; 
	always @(*) begin
		srd = 32'b0;                          // default - no inferred latch
		if(rv32i_inst)
		begin
			if(alu_imm)
				case (funct3)
					3'b000 :   srd = rs1+$signed(imm) ;      // ADDI
					3'b010 :   srd = $signed(rs1) < $signed(imm) ? 1 : 0;  // SLTI  signed
					3'b011 :   srd = rs1 < imm ? 1 : 0;  // SLTIU unsigned
					3'b100 :   srd = rs1^imm;      // XORI
					3'b110 :   srd = rs1|imm;      // ORI
					3'b111 :   srd = rs1&imm;      // ANDI
					3'b001 :   srd = rs1 <<< imm[4:0];    // SLLI
					3'b101 :  begin
									if(modbit == 1'b0 ) srd =  rs1 >> imm[4:0];// SRLI
									else srd =  $signed(rs1) >>> (imm[4:0]); // SRAI
								end 
				 endcase
			 else
				case (funct3)
					3'b000 :   srd = (modbit == 1'b0) ? 
																rs1 + rs2 :    // ADD
																rs1 - rs2;     // SUB
					3'b001 :   srd = rs1 << rs2[4:0];	// SLL
					3'b010 :   srd = $signed(rs1) < $signed(rs2) ? 1 : 0;	// SLT
					3'b011 :   srd = rs1 < rs2 ? 1 : 0;	// SLTU
					3'b100 :   srd = rs1 ^ rs2;	// XOR
					3'b101 :   begin
									if(modbit == 1'b0 ) srd =  rs1 >> rs2[4:0] ;// SRLI
									else srd =  $signed(rs1) >>> rs2[4:0]; // SRAI
								end 					
					3'b110 :   srd = rs1|rs2;      // OR
					3'b111 :   srd = rs1&rs2;      // AND
				endcase
			end
		if(rv32m_inst)
			begin
			case (funct3)
			3'b000:  srd = prod[31:0];               // MUL
			3'b001,
			3'b010,
			3'b011:  srd = prod[63:32];              // MULH, MULHSU, MULHU
			default: srd = 32'b0;  
	    	endcase
		end
	end
	


	reg [2:0] op_f3;
	
	// Division State Machine	
	always @ ( posedge clk) begin
		if(div_req)
		begin
		case(cState)
		IDLE: 
				begin
					op_f3 <= funct3;
					numer <= rs1;
					denom <= rs2;
				//	if(imm[5]) 
				//	begin
					case (op_f3)
						3'b100,3'b101 ,3'b110 ,3'b111  :  begin
								div_counter <= DIV_DELAY;
							 end

					endcase						
				//	end
				end
			DIV_WAIT: 
				begin	
						div_counter <= div_counter - 4'b1;
				end
			DIV_COMP: 
				begin	
					case (op_f3)
						3'b100:  d_rd <= quotient;
						3'b101:  d_rd <= uquotient;
						3'b110:  d_rd <= remain;
						3'b111:  d_rd <= uremain;
						3'b000:  
						begin
							d_rd <= prod[31:0];   // MUL
							div_counter <= 0;
						end
						3'b001,
						3'b010,
						3'b011: 
						begin
							d_rd <= prod[63:32];  // MULH, MULHSU, MULHU
							div_counter <= 0;
						end
						default:
						begin
							d_rd <= 32'b0;        // DIV/REM handled elsewhere
							 div_counter <= 0;
							end
					endcase
				end
			endcase
		end
	end
	
// FSM
	always@(posedge clk) begin
		if(~reset)
		begin
			cState <= IDLE;
		end
		else
			cState <= nState;
	end


	// Memeory burst FSM
	always@ ( * ) begin
		case(cState)
			 IDLE: begin
				if(div_req)
				begin
			//		if(opcode == 7'b0110011 && imm[5])
				//	begin
				//		if(funct3[2]) 
						nState = DIV_WAIT;
					//	else nState = DONE;
				//	end
				//	else nState = DONE;
				end
				else nState = IDLE;
				end
			 DIV_WAIT:
					 begin
						if(div_counter==0) nState = DIV_COMP;
						else nState = DIV_WAIT;
					 end	
			 DIV_COMP:
					 begin
						nState = DONE;
					 end	
			 DONE:
					 begin
						nState = IDLE;
					 end	
		endcase
	end			
	
		

endmodule