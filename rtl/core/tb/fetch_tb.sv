`timescale 1ns / 1ps

module fetch_tb;
  reg         mclk = 1'b0;
  reg         reset = 1'b0;
  reg         decoder_ready = 1'b0;
  reg         branch_taken = 1'b0;
  reg  [31:0] branch_target = 32'b0;

  wire        ID_ready = decoder_ready;
  wire [31:0] addr_i;
  wire [1:0]  size_i;
  wire [31:0] mem_read_data;
  wire        m_valid;
  wire        s_valid;
  wire        IFID_valid;
  wire [31:0] IFID_inst;
  wire [31:0] IFID_pc;

  integer checks = 0;
  integer failures = 0;
  integer cycles;

  fetch u_fetch(
    .mclk(mclk),
    .reset(reset),
    .sys_ready(1'b1),
    .stall(1'b0),
    .ifid_flush(1'b0),
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .addr_i(addr_i),
    .size_i(size_i),
    .mem_read_data(mem_read_data),
    .m_valid(m_valid),
    .s_valid(s_valid),
    .IFID_inst(IFID_inst),
    .IFID_pc(IFID_pc),
    .IFID_valid(IFID_valid),
    .ID_ready(ID_ready)
  );

  mmu_sim_model #(
    .MEM_BYTES(4096),
    .RESP_LATENCY(0)
  ) memory (
    .mclk(mclk),
    .reset(reset),
    .address(addr_i),
    .rw(1'b0),
    .write_data(32'b0),
    .size(size_i),
    .read_data(mem_read_data),
    .m_valid(m_valid),
    .s_valid(s_valid)
  );

  always #5 mclk = ~mclk;

  task check;
    input condition;
    input [8*80-1:0] message;
    begin
      checks = checks + 1;
      if (condition !== 1'b1) begin
        failures = failures + 1;
        $display("FAIL: %0s (time=%0t)", message, $time);
      end else begin
        $display("PASS: %0s", message);
      end
    end
  endtask

  task wait_for_request;
    input [31:0] expected_address;
    input [8*80-1:0] message;
    begin
      cycles = 0;
      while (m_valid !== 1'b1 && cycles < 20) begin
        @(posedge mclk);
        #1;
        cycles = cycles + 1;
      end
      check(m_valid === 1'b1, "fetch issues a memory request before timeout");
      check(addr_i === expected_address, message);
    end
  endtask

  task wait_for_instruction;
    input [31:0] expected_instruction;
    input [31:0] expected_pc;
    begin
      cycles = 0;
      while (IFID_valid !== 1'b1 && cycles < 20) begin
        @(posedge mclk);
        #1;
        cycles = cycles + 1;
      end
      check(IFID_valid === 1'b1, "memory response produces a valid IF/ID entry");
      check(IFID_inst === expected_instruction, "IF/ID instruction matches memory response");
      check(IFID_pc === expected_pc, "IF/ID PC matches expected sequence");
    end
  endtask

  task expect_no_request;
    input [8*80-1:0] message;
    begin
      repeat (2) begin
        @(posedge mclk);
        #1;
        check(m_valid === 1'b0, message);
      end
    end
  endtask

  initial begin
    $dumpfile("fetch.vcd");
    $dumpvars(0, fetch_tb);

    memory.poke_word(32'h000000c0, 32'hDEADBEEF);
    memory.poke_word(32'h00000004, 32'h12345678);
    memory.poke_word(32'h00000008, 32'hCAFEBABE);
    memory.poke_word(32'h0000000c, 32'h0BADF00D);
    memory.poke_word(32'h00000040, 32'h87654321);

    repeat (2) @(posedge mclk);
    #1 reset = 1'b1;

    // The first fetch is launched by the stage's initialization state.
    wait_for_request(32'h000000c0, "initial request uses the initialized address");
    wait_for_instruction(32'hDEADBEEF, 32'h00000000);

    // Model the decoder back-pressuring fetch until it can accept IF/ID.
    decoder_ready = 1'b0;
    expect_no_request("decoder not-ready prevents the next fetch request");
    decoder_ready = 1'b1;

    wait_for_request(32'h00000004, "sequential request advances PC by four");
    wait_for_instruction(32'h12345678, 32'h00000004);
    wait_for_request(32'h00000008, "second sequential request advances PC by four");

    // Pulse a taken branch while the request at 0x08 is awaiting its response.
    // The target assertion below documents the known branch redirect failure.
    branch_target = 32'h00000040;
    branch_taken = 1'b1;
    wait_for_instruction(32'h00000013, 32'h00000008);
    branch_taken = 1'b0;

    wait_for_request(32'h00000040, "taken branch must fetch from its target");
    if (addr_i === branch_target)
      wait_for_instruction(32'h87654321, 32'h00000040);
    else
      $display("Observed fetch address after branch: %08h", addr_i);

    if (failures == 0) begin
      $display("fetch_tb: PASS (%0d checks)", checks);
      $finish;
    end else begin
      $display("fetch_tb: FAIL (%0d checks, %0d failures)", checks, failures);
      $fatal(1, "fetch_tb detected behavior that does not match the expected flow");
    end
  end
endmodule

