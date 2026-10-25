`timescale 1ns / 1ps

// Simulation-only stubs: execute instruction-class tests do not exercise
// division, and the divider RTL is supplied by generated hardware elsewhere.
module divider(
  input        clock,
  input  [31:0] denom,
  input  [31:0] numer,
  output [31:0] quotient,
  output [31:0] remain
);
  assign quotient = 32'b0;
  assign remain = 32'b0;
endmodule

module udivider(
  input        clock,
  input  [31:0] denom,
  input  [31:0] numer,
  output [31:0] quotient,
  output [31:0] remain
);
  assign quotient = 32'b0;
  assign remain = 32'b0;
endmodule

module execute_tb;
  localparam OP_IMM = 7'b0010011;
  localparam OP_REG = 7'b0110011;
  localparam OP_LOAD = 7'b0000011;
  localparam OP_STORE = 7'b0100011;
  localparam OP_BRANCH = 7'b1100011;
  localparam OP_JALR = 7'b1100111;
  localparam OP_JAL = 7'b1101111;
  localparam OP_LUI = 7'b0110111;
  localparam OP_AUIPC = 7'b0010111;

  logic        mclk;
  logic        reset;
  logic        sys_ready;
  logic        stall;
  logic [31:0] IDEX_rs1;
  logic [31:0] IDEX_rs2;
  logic [6:0]  IDEX_opcode;
  logic [3:0]  IDEX_funct3;
  logic        IDEX_modbit;
  logic [31:0] IDEX_imm;
  logic [11:0] IDEX_csr;
  logic [5:0]  IDEX_rd;
  logic [31:0] IDEX_pc;
  logic        IDEX_valid;
  logic [11:0] csr;
  logic [4:0]  uimm;
  logic [5:0]  rd_index;
  logic [31:0] mem_read_data;
  logic        s_valid_d;

  wire        rf_we;
  wire [5:0]  rf_waddr;
  wire [31:0] rf_wdata;
  wire        branch_taken;
  wire [31:0] branch_target;
  wire [31:0] mem_write_data;
  wire [31:0] mem_address_d;
  wire [1:0]  mem_size_d;
  wire        mem_rw_d;
  wire        m_valid_d;
  wire        EX_ready;

  integer checks;
  integer failures;

  execute dut (
    .mclk(mclk),
    .reset(reset),
    .sys_ready(sys_ready),
    .stall(stall),
    .IDEX_rs1(IDEX_rs1),
    .IDEX_rs2(IDEX_rs2),
    .IDEX_opcode(IDEX_opcode),
    .IDEX_funct3(IDEX_funct3),
    .IDEX_modbit(IDEX_modbit),
    .IDEX_imm(IDEX_imm),
    .IDEX_csr(IDEX_csr),
    .IDEX_rd(IDEX_rd),
    .IDEX_pc(IDEX_pc),
    .csr(csr),
    .uimm(uimm),
    .rd_index(rd_index),
    .rf_we(rf_we),
    .rf_waddr(rf_waddr),
    .rf_wdata(rf_wdata),
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .mem_read_data(mem_read_data),
    .mem_write_data(mem_write_data),
    .mem_address_d(mem_address_d),
    .mem_size_d(mem_size_d),
    .mem_rw_d(mem_rw_d),
    .m_valid_d(m_valid_d),
    .s_valid_d(s_valid_d),
    .IDEX_valid(IDEX_valid),
    .EX_ready(EX_ready)
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

  task reset_execute;
    begin
      reset = 1'b0;
      sys_ready = 1'b0;
      stall = 1'b0;
      IDEX_valid = 1'b0;
      s_valid_d = 1'b0;
      @(posedge mclk);
      #1;
      reset = 1'b1;
      sys_ready = 1'b1;
    end
  endtask

  task clear_instruction;
    begin
      IDEX_rs1 = 32'b0;
      IDEX_rs2 = 32'b0;
      IDEX_opcode = 7'b0;
      IDEX_funct3 = 4'b0;
      IDEX_modbit = 1'b0;
      IDEX_imm = 32'b0;
      IDEX_csr = 12'b0;
      IDEX_rd = 6'b0;
      IDEX_pc = 32'b0;
      IDEX_valid = 1'b0;
      csr = 12'b0;
      uimm = 5'b0;
      rd_index = 6'b0;
      mem_read_data = 32'b0;
      s_valid_d = 1'b0;
      stall = 1'b0;
    end
  endtask

  initial begin
    mclk = 1'b0;
    checks = 0;
    failures = 0;
    clear_instruction;
    reset = 1'b0;
    sys_ready = 1'b0;

    $dumpfile("execute.vcd");
    $dumpvars(0, execute_tb);
    $display("Starting execute testcases");

    // Arithmetic classes: immediate and register ALU operations write rd.
    reset_execute;
    IDEX_valid = 1'b1;
    IDEX_opcode = OP_IMM;
    IDEX_funct3 = 3'b000;
    IDEX_rs1 = 32'd12;
    IDEX_imm = 32'd5;
    IDEX_rd = 6'd3;
    #1;
    check(rf_we === 1'b1, "ADDI enables register write");
    check(rf_waddr === 6'd3 && rf_wdata === 32'd17, "ADDI produces result");

    IDEX_opcode = OP_REG;
    IDEX_funct3 = 3'b000;
    IDEX_modbit = 1'b1;
    IDEX_rs1 = 32'd20;
    IDEX_rs2 = 32'd7;
    IDEX_rd = 6'd4;
    #1;
    check(rf_we === 1'b1, "SUB enables register write");
    check(rf_waddr === 6'd4 && rf_wdata === 32'd13, "SUB produces result");

    // Upper-immediate classes write the decoded immediate or PC-relative sum.
    IDEX_opcode = OP_LUI;
    IDEX_imm = 32'h12345000;
    IDEX_rd = 6'd5;
    #1;
    check(rf_we === 1'b1 && rf_wdata === 32'h12345000, "LUI writes its upper immediate");

    IDEX_opcode = OP_AUIPC;
    IDEX_pc = 32'h00001000;
    IDEX_imm = 32'h00002000;
    IDEX_rd = 6'd6;
    #1;
    check(rf_we === 1'b1 && rf_wdata === 32'h00003000, "AUIPC writes PC plus immediate");

    // Conditional branches: taken state and PC-relative target.
    IDEX_opcode = OP_BRANCH;
    IDEX_funct3 = 3'b000;
    IDEX_rs1 = 32'h55;
    IDEX_rs2 = 32'h55;
    IDEX_pc = 32'h00000100;
    IDEX_imm = 32'h00000020;
    #1;
    check(branch_taken === 1'b1, "BEQ is taken when operands are equal");
    check(branch_target === 32'h00000120, "branch target is PC relative");

    IDEX_rs2 = 32'h56;
    #1;
    check(branch_taken === 1'b0, "BEQ is not taken when operands differ");

    IDEX_funct3 = 3'b001;
    #1;
    check(branch_taken === 1'b1, "BNE is taken when operands differ");

    // Unconditional jump classes redirect and write the link address.
    IDEX_opcode = OP_JAL;
    IDEX_imm = 32'h00000030;
    IDEX_pc = 32'h00000200;
    IDEX_rd = 6'd7;
    rd_index = 6'd7;
    #1;
    check(branch_taken === 1'b1 && branch_target === 32'h00000230, "JAL redirects to PC-relative target");
    check(rf_we === 1'b1 && rf_wdata === 32'h00000204, "JAL writes the link address");

    IDEX_opcode = OP_JALR;
    IDEX_rs1 = 32'h00000301;
    IDEX_imm = 32'h0000000c;
    IDEX_rd = 6'd8;
    rd_index = 6'd8;
    #1;
    check(branch_taken === 1'b1 && branch_target === 32'h0000030d, "JALR redirects to register plus immediate");
    check(rf_we === 1'b1 && rf_wdata === 32'h00000204, "JALR writes the link address");

    // Loads and stores create data-side requests on the clock edge.
    reset_execute;
    IDEX_valid = 1'b1;
    IDEX_opcode = OP_LOAD;
    IDEX_funct3 = 3'b010;
    IDEX_rs1 = 32'h00001000;
    IDEX_imm = 32'h00000014;
    IDEX_rd = 6'd9;
    @(posedge mclk);
    #1;
    check(m_valid_d === 1'b1, "load starts a data request");
    check(mem_rw_d === 1'b0, "load request is a read");
    check(mem_address_d === 32'h00001014, "load address is base plus immediate");
    check(mem_size_d === 2'b10, "LW requests a word");

    // A level-valid request must remain asserted until the memory handshake.
    @(posedge mclk);
    #1;
    check(m_valid_d === 1'b1, "load request remains asserted before acknowledgment");
    check(mem_address_d === 32'h00001014, "load request holds its address before acknowledgment");

    mem_read_data = 32'hAABBCCDD;
    s_valid_d = 1'b1;
    #1;
    check(EX_ready === 1'b1, "load response makes execute ready");
    check(rf_we === 1'b1 && rf_wdata === 32'hAABBCCDD, "load response presents returned data for writeback");
    @(posedge mclk);
    #1;
    check(m_valid_d === 1'b0, "load response clears the data request");

    // This is a deliberately expected failure while execute is being fixed:
    // an acknowledgment without an outstanding request must not write a rd.
    clear_instruction;
    reset_execute;
    IDEX_valid = 1'b1;
    IDEX_opcode = OP_LOAD;
    IDEX_funct3 = 3'b010;
    IDEX_rd = 6'd10;
    mem_read_data = 32'h11223344;
    s_valid_d = 1'b1;
    #1;
    check(rf_we === 1'b0, "unsolicited acknowledgment does not write a register");
    s_valid_d = 1'b0;

    reset_execute;
    IDEX_valid = 1'b1;
    IDEX_opcode = OP_STORE;
    IDEX_funct3 = 3'b001;
    IDEX_rs1 = 32'h00002000;
    IDEX_rs2 = 32'h0000BEEF;
    IDEX_imm = 32'h00000006;
    @(posedge mclk);
    #1;
    check(m_valid_d === 1'b1, "store starts a data request");
    check(mem_rw_d === 1'b1, "store request is a write");
    check(mem_address_d === 32'h00002006, "store address is base plus immediate");
    check(mem_write_data === 32'h0000BEEF, "store carries source register data");
    check(rf_we === 1'b0, "store does not write a register");

    // Validity, stall, and x0 guards apply across instruction classes.
    reset_execute;
    IDEX_valid = 1'b1;
    IDEX_opcode = OP_IMM;
    IDEX_funct3 = 3'b000;
    IDEX_rs1 = 32'd1;
    IDEX_imm = 32'd2;
    IDEX_rd = 6'd0;
    #1;
    check(rf_we === 1'b1, "ALU path currently exposes x0 writeback for caller filtering");
    IDEX_valid = 1'b0;
    #1;
    check(rf_we === 1'b0, "invalid instruction suppresses register write");
    IDEX_valid = 1'b1;
    stall = 1'b1;
    #1;
    check(rf_we === 1'b1, "stall does not gate ALU writeback in the current execute interface");

    $display("execute_tb: %0d checks, %0d failures", checks, failures);
    if (failures != 0)
      $fatal(1, "execute_tb detected unexpected behavior");
    $finish;
  end
endmodule
