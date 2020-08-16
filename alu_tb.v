`timescale 1ns / 1ps

module alu_testbench;


	reg clk;
	reg [2:0] funct3;
	reg modbit;
	reg [31:0] imm;
	reg [6:0] opcode;
	reg [31:0] rs1;
	reg [31:0] rs2;
	wire [31:0] rd;

	alu  alu(clk, funct3, modbit, imm, opcode, rs1, rs2,rd);

	initial
		begin
		$dumpfile ("alu.vcd");
		$dumpvars (1, alu);
		$monitor ("rd=%b,",rd);

		opcode=7'b0110011;
		funct3=3'b000;
		modbit=0;
		rs1='d150;
		rs2='d50;
		
		clk=0;
		#10
		clk = 1;
		#10
		clk = 0;
		#10

		$finish;
	end

endmodule
