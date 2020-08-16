module alu(input wire clk,
			  input wire [2:0] funct3,
			  input wire modbit,
			  input wire [31:0] imm,
			  input wire [6:0] opcode,
			  input wire [31:0] rs1,
			  input wire [31:0] rs2,
			  output wire [31:0] rd,
			  output reg comp);
	
	reg [31:0] i_rd;	
		
	assign rd = i_rd;

	always @ ( posedge clk) begin
		case(opcode)
				7'b0010011 :
					begin
						case (funct3)
							3'b000 :   i_rd <= $signed(rs1)+$signed(imm);      // ADDI
							3'b010 :   i_rd <= $signed(rs1) < $signed(imm) ? 1 : 0;  // SLTI  signed
							3'b011 :   i_rd <= rs1 < imm ? 1 : 0;  // SLTIU unsigned
							3'b100 :   i_rd <= rs1^imm;      // XORI
							3'b110 :   i_rd <= rs1|imm;      // ORI
							3'b111 :   i_rd <= rs1&imm;      // ANDI
							3'b001 :   i_rd <= rs1 << (imm & 5'b11111);    // SLLI
							3'b101 :   i_rd <= modbit == 1'b0 ? 
																		rs1 >> (imm & 5'b11111) :    // SRLI
																		$signed(rs1) >> (imm & 5'b11111);  // SRAI
							// TODO Default excpetion
						 endcase
					end
				 7'b0110011 :
					begin
						case (funct3)
							3'b000 :   i_rd <= modbit == 1'b0 ? 
																		rs1 + rs2 :    // ADD
																		rs1 - rs2;     // SUB
							3'b001 :   i_rd <= rs1 << (rs2 & 5'b11111);	// SLL
							3'b010 :   i_rd <= $signed(rs1) < $signed(rs2) ? 1 : 0;	// SLT
							3'b011 :   i_rd <= rs1 < rs2 ? 1 : 0;	// SLTU
							3'b100 :   i_rd <= rs1 ^ rs2;	// XOR
							3'b101 :   i_rd <= modbit == 1'b0 ? 
																		rs1 >> (	rs2  & 5'b11111) :    // SRL
																		$signed(rs1) >> (	rs2  & 5'b11111);  // SRA						
							3'b110 :   i_rd <= rs1|rs2;      // OR
							3'b111 :   i_rd <= rs1&rs2;      // AND
							// TODO Default excpetion
						 endcase
					end
			endcase
			comp <=1;
	end
endmodule