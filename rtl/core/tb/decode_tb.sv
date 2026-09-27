`timescale 1ns / 1ps

module decode_tb;
  logic        mclk;
  logic        sys_ready;
  logic        stall;
  logic        idex_flush;
  logic        IFID_valid;
  logic [31:0] IFID_inst;
  logic [31:0] IFID_pc;
  logic        rf_we;
  logic [5:0]  rf_waddr;
  logic [31:0] rf_wdata;

  wire [31:0] rs1_data;
  wire [31:0] rs2_data;
  wire [11:0] csr;
  wire [4:0]  uimm;
  wire [5:0]  rd_index;
  wire [31:0] IDEX_rs1;
  wire [31:0] IDEX_rs2;
  wire [6:0]  IDEX_opcode;
  wire [3:0]  IDEX_funct3;
  wire        IDEX_modbit;
  wire [31:0] IDEX_imm;
  wire [11:0] IDEX_csr;
  wire [5:0]  IDEX_rd;
  wire [31:0] IDEX_pc;
  wire        IDEX_valid;

  integer checks;
  integer failures;

  decode dut (
    .mclk(mclk),
    .sys_ready(sys_ready),
    .stall(stall),
    .idex_flush(idex_flush),
    .IFID_valid(IFID_valid),
    .IFID_inst(IFID_inst),
    .IFID_pc(IFID_pc),
    .rf_we(rf_we),
    .rf_waddr(rf_waddr),
    .rf_wdata(rf_wdata),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .csr(csr),
    .uimm(uimm),
    .rd_index(rd_index),
    .IDEX_rs1(IDEX_rs1),
    .IDEX_rs2(IDEX_rs2),
    .IDEX_opcode(IDEX_opcode),
    .IDEX_funct3(IDEX_funct3),
    .IDEX_modbit(IDEX_modbit),
    .IDEX_imm(IDEX_imm),
    .IDEX_csr(IDEX_csr),
    .IDEX_rd(IDEX_rd),
    .IDEX_pc(IDEX_pc),
    .IDEX_valid(IDEX_valid)
  );

  always #5 mclk = ~mclk;

  task check;
    input condition;
    input [255:0] message;
    begin
      checks = checks + 1;
      if (!condition) begin
        failures = failures + 1;
        $display("FAIL: %s", message);
      end
    end
  endtask

  task write_register;
    input [5:0] address;
    input [31:0] value;
    begin
      rf_we = 1'b1;
      rf_waddr = address;
      rf_wdata = value;
      @(posedge mclk);
      #1;
      rf_we = 1'b0;
    end
  endtask

  task capture;
    input [31:0] instruction;
    input [31:0] pc;
    begin
      IFID_inst = instruction;
      IFID_pc = pc;
      IFID_valid = 1'b1;
      @(posedge mclk);
      #1;
    end
  endtask

  initial begin
    mclk = 1'b0;
    sys_ready = 1'b0;
    stall = 1'b0;
    idex_flush = 1'b0;
    IFID_valid = 1'b0;
    IFID_inst = 32'b0;
    IFID_pc = 32'b0;
    rf_we = 1'b0;
    rf_waddr = 6'b0;
    rf_wdata = 32'b0;
    checks = 0;
    failures = 0;

    @(posedge mclk);
    #1;
    check(IDEX_valid === 1'b0, "reset clears IDEX_valid");
    sys_ready = 1'b1;

    write_register(6'd1, 32'h00000011);
    write_register(6'd2, 32'h00000022);
    write_register(6'd3, 32'h00000033);

    // addi x5, x2, -4
    capture(32'hffc10293, 32'h00000100);
    check(IDEX_valid === 1'b1, "I-type instruction becomes valid");
    check(IDEX_opcode === 7'b0010011, "I-type opcode decodes");
    check(IDEX_funct3 === 3'b000, "I-type funct3 decodes");
    check(IDEX_imm === 32'hfffffffc, "I-type immediate sign extends");
    check(IDEX_rs1 === 32'h00000022, "rs1 reads the register file");
    check(IDEX_rd === 6'd5 && IDEX_pc === 32'h00000100, "rd and pc latch");

    // add x6, x5, x2 while EX writes x5: the ID/EX operand must forward.
    IFID_inst = 32'h00228333;
    IFID_pc = 32'h00000104;
    IFID_valid = 1'b1;
    rf_we = 1'b1;
    rf_waddr = 6'd5;
    rf_wdata = 32'h00000055;
    @(posedge mclk);
    #1;
    rf_we = 1'b0;
    check(IDEX_rs1 === 32'h00000055, "EX result forwards to rs1");
    check(IDEX_rs2 === 32'h00000022, "non-forwarded rs2 reads normally");
    check(rs1_data === 32'h00000055, "unforwarded rs1 output is architectural read");

    // sw x5, 12(x3)
    capture(32'h0051a623, 32'h00000108);
    check(IDEX_imm === 32'h0000000c, "S-type immediate decodes");
    check(IDEX_rs1 === 32'h00000033, "S-type base register decodes");
    check(IDEX_rs2 === 32'h00000055, "S-type source register decodes");

    // beq x1, x2, -4
    capture(32'hfe208ee3, 32'h0000010c);
    check(IDEX_opcode === 7'b1100011, "B-type opcode decodes");
    check(IDEX_imm === 32'hfffffffc, "B-type immediate sign extends");

    // lui x7, 0x12345000
    capture(32'h123453b7, 32'h00000110);
    check(IDEX_imm === 32'h12345000, "U-type immediate decodes");
    check(IDEX_rd === 6'd7, "U-type rd decodes");

    // jal x8, 16
    capture(32'h0100046f, 32'h00000114);
    check(IDEX_opcode === 7'b1101111, "J-type opcode decodes");
    check(IDEX_imm === 32'h00000010, "J-type immediate decodes");

    // A stall holds the previous ID/EX contents.
    IFID_inst = 32'h00000013;
    IFID_pc = 32'h00000118;
    stall = 1'b1;
    @(posedge mclk);
    #1;
    check(IDEX_pc === 32'h00000114 && IDEX_valid === 1'b1, "stall holds ID/EX");
    stall = 1'b0;

    // An invalid IF/ID entry creates a bubble.
    IFID_valid = 1'b0;
    @(posedge mclk);
    #1;
    check(IDEX_valid === 1'b0, "invalid IF/ID creates a bubble");

    // Flush wins over a valid instruction.
    IFID_valid = 1'b1;
    idex_flush = 1'b1;
    @(posedge mclk);
    #1;
    check(IDEX_valid === 1'b0 && IDEX_opcode === 7'b0, "flush clears ID/EX");

    $display("decode_tb: %0d checks, %0d failures", checks, failures);
    if (failures != 0)
      $fatal(1);
    $finish;
  end
endmodule
