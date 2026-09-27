module alu(input wire clk,
			  input wire div_req,
			  input wire reset,
			  input wire [2:0] funct3,
			  input wire modbit,
			  input wire [31:0] imm,
			  input wire [6:0] opcode,
			  input wire [31:0] rs1,
			  input wire [31:0] rs2,
			  output reg [31:0] rd,
			  output wire comp);
	
	
	
	localparam 	IDLE = 2'd0,
				   DIV_WAIT = 2'd1,
					DIV_COMP = 2'd2,
					DONE = 2'd3;
		
	localparam 	DIV_DELAY = 4'd5;	
	
	
	reg [5:0] div_counter;
	
	
	reg [31:0] d_rd;	
		
	//assign rd = i_rd;

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
		

	// RV32I	
	
	wire is_imm = (opcode == 7'b0010011);   // OP-IMM
	wire is_reg = (opcode == 7'b0110011);   // OP

	assign alu_imm    = is_imm;
	assign rv32i_inst = is_imm | (is_reg & ~imm[5]);  // imm[5]==funct7[0]==RV32M

	always @(*) begin
		rd = 32'b0;                          // default - no inferred latch
		if(rv32i_inst)
		begin
			if(alu_imm)
				case (funct3)
					3'b000 :   rd = rs1+$signed(imm) ;      // ADDI
					3'b010 :   rd = $signed(rs1) < $signed(imm) ? 1 : 0;  // SLTI  signed
					3'b011 :   rd = rs1 < imm ? 1 : 0;  // SLTIU unsigned
					3'b100 :   rd = rs1^imm;      // XORI
					3'b110 :   rd = rs1|imm;      // ORI
					3'b111 :   rd = rs1&imm;      // ANDI
					3'b001 :   rd = rs1 <<< imm[4:0];    // SLLI
					3'b101 :  begin
									if(modbit == 1'b0 ) rd =  rs1 >> imm[4:0];// SRLI
									else rd =  $signed(rs1) >>> (imm[4:0]); // SRAI
								end 
				 endcase
			 else
				case (funct3)
					3'b000 :   rd = (modbit == 1'b0) ? 
																rs1 + rs2 :    // ADD
																rs1 - rs2;     // SUB
					3'b001 :   rd = rs1 << rs2[4:0];	// SLL
					3'b010 :   rd = $signed(rs1) < $signed(rs2) ? 1 : 0;	// SLT
					3'b011 :   rd = rs1 < rs2 ? 1 : 0;	// SLTU
					3'b100 :   rd = rs1 ^ rs2;	// XOR
					3'b101 :   begin
									if(modbit == 1'b0 ) rd =  rs1 >> rs2[4:0] ;// SRLI
									else rd =  $signed(rs1) >>> rs2[4:0]; // SRAI
								end 					
					3'b110 :   rd = rs1|rs2;      // OR
					3'b111 :   rd = rs1&rs2;      // AND
				endcase
			end
			/*if(mult_inst)
			case (funct3)
					3'b000 :   rd = (rs1 * rs2); // MUL
					3'b001 :   rd =  ({ {32{rs1[31]}},rs1} * { {32{rs2[31]}},rs2}) >>32;	// MULH
					3'b010 :   rd = ({ {32{rs1[31]}},rs1}  * {32'b0,rs2}) >>32;	// MULHSU
					3'b011 :   rd = ({32'b0,rs1} * {32'b0,rs2}) >>32;	// MULHU
			endcase*/
	end
	
	reg mult_inst;


	
	// Division State Machine	
	always @ ( posedge clk) begin
		if(div_req)
		begin
		case(cState)
		IDLE: 
				begin
					div_counter <= DIV_DELAY;
					if(imm[5]) 
					begin
					case (funct3)
						3'b100,3'b101 ,3'b110 ,3'b111  :  begin
								numer <= rs1;
								denom <= rs2;
							 end
						endcase						
					end
				end
			DIV_WAIT: 
				begin	
						div_counter <= div_counter - 4'b1;
				end
			DIV_COMP: 
				begin	
					case (funct3[1:0])
						2'b00:  d_rd <= quotient;
						2'b01:  d_rd <= uquotient;
						2'b10:  d_rd <= remain;
						2'b11:  d_rd <= uremain;
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
				if(div_req)
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