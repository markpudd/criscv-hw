module alu(input wire clk,
			  input wire req,
			  input wire reset,
			  input wire [2:0] funct3,
			  input wire modbit,
			  input wire [31:0] imm,
			  input wire [6:0] opcode,
			  input wire [31:0] rs1,
			  input wire [31:0] rs2,
			  output wire [31:0] rd,
			  output wire comp);
	
	localparam 	IDLE = 2'd0,
				   DIV_WAIT = 2'd1,
					DIV_COMP = 2'd2,
					DONE = 2'd3;
		
	localparam 	DIV_DELAY = 4'd5;	
	
	
	reg [5:0] div_counter;
	
	
	reg [31:0] i_rd;	
		
	assign rd = i_rd;

	reg [1:0] nState;
	reg [1:0] cState;
	
	reg [31:0] denom;
	reg [31:0] numer;
	wire [31:0] quotient;
	wire [31:0] remain;
	wire [31:0] uquotient;
	wire [31:0] uremain;
	
	assign comp =(cState == DONE);

		
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
						
	always @ ( posedge clk) begin
		if(req)
		begin
		case(cState)
		IDLE: 
				begin
				div_counter <= DIV_DELAY;
					case(opcode)
						7'b0010011 :
							begin
								case (funct3)
									3'b000 :   i_rd <= rs1+$signed(imm);      // ADDI
									3'b010 :   i_rd <= $signed(rs1) < $signed(imm) ? 1 : 0;  // SLTI  signed
									3'b011 :   i_rd <= rs1 < imm ? 1 : 0;  // SLTIU unsigned
									3'b100 :   i_rd <= rs1^imm;      // XORI
									3'b110 :   i_rd <= rs1|imm;      // ORI
									3'b111 :   i_rd <= rs1&imm;      // ANDI
									3'b001 :   i_rd <= rs1 <<< imm[4:0];    // SLLI
									3'b101 :  begin
													if(modbit == 1'b0 ) i_rd <=  rs1 >> imm[4:0];// SRLI
													else i_rd <=  $signed(rs1) >>> (imm[4:0]); // SRAI
												end 
									// TODO Default excpetion
								 endcase
							end
						 7'b0110011 :
							begin
								if(imm[5]) 
								begin
								case (funct3)
									3'b000 :   i_rd <= (rs1 * rs2); // MUL
									3'b001 :   i_rd <=  ({ {32{rs1[31]}},rs1} * { {32{rs2[31]}},rs2}) >>32;	// MULH
									3'b010 :   i_rd <= ({ {32{rs1[31]}},rs1}  * {32'b0,rs2}) >>32;	// MULHSU
									3'b011 :   i_rd <= ({32'b0,rs1} * {32'b0,rs2}) >>32;	// MULHU
					    			3'b100 :  begin
													numer <= rs1;
													denom <= rs2;
												 end
					    			3'b101 :  begin
													numer <= rs1;
													denom <= rs2;
												 end
								    3'b110 :  begin
													numer <= rs1;
													denom <= rs2;
												 end
									3'b111 :  begin
													numer <= rs1;
													denom <= rs2;
												 end
									endcase						
								end
								else
								begin	
								case (funct3)
									3'b000 :   i_rd <= (modbit == 1'b0) ? 
																				rs1 + rs2 :    // ADD
																				rs1 - rs2;     // SUB
									3'b001 :   i_rd <= rs1 << rs2[4:0];	// SLL
									3'b010 :   i_rd <= $signed(rs1) < $signed(rs2) ? 1 : 0;	// SLT
									3'b011 :   i_rd <= rs1 < rs2 ? 1 : 0;	// SLTU
									3'b100 :   i_rd <= rs1 ^ rs2;	// XOR
									3'b101 :   begin
													if(modbit == 1'b0 ) i_rd <=  rs1 >> rs2[4:0] ;// SRLI
													else i_rd <=  $signed(rs1) >>> rs2[4:0]; // SRAI
												end 					
									3'b110 :   i_rd <= rs1|rs2;      // OR
									3'b111 :   i_rd <= rs1&rs2;      // AND
									// TODO Default excpetion
								 endcase
								 end
							end
					endcase
				end
			DIV_WAIT: 
				begin	
						div_counter <= div_counter - 4'b1;
				end
			DIV_COMP: 
				begin	
					case (funct3[1:0])
						2'b00:  i_rd <= quotient;
						2'b01:  i_rd <= uquotient;
						2'b10:  i_rd <= remain;
						2'b11:  i_rd <= uremain;
					endcase
				end
			endcase
		end
	end
	
// FSM
	always@(posedge clk) begin
		if(~reset)
		begin
			cState = IDLE;
		end
		else
			cState <= nState;
	end


	// Memeory burst FSM
	always@ ( * ) begin
		case(cState)
			 IDLE: begin
				if(req)
				begin
					if(opcode == 7'b0110011 && imm[5])
					begin
						if(funct3[2]) nState = DIV_WAIT;
						else nState = DONE;
					end
					else nState = DONE;
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