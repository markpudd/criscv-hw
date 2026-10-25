`timescale 1ns / 1ps

module fetch_tb;
  reg         mclk = 1'b0;
  reg         reset = 1'b0;
  reg         sys_ready = 1'b0;
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

  reg         memory_enable = 1'b0;
  reg         request_valid = 1'b0;
  reg  [31:0] request_addr = 32'b0;
  reg  [31:0] request_data = 32'b0;
  reg         response_valid = 1'b0;
  reg  [31:0] response_addr = 32'b0;
  reg  [31:0] response_data = 32'b0;
  reg  [31:0] instruction_mem [0:63];
  reg         response_for_fetch;
  reg  [31:0] checked_response_addr;
  reg  [31:0] checked_response_data;
  reg  [31:0] expected_request_addr = 32'b0;
  reg  [31:0] expected_ifid_pc = 32'b0;
  integer checks = 0;
  integer failures = 0;
  integer index;
  integer cycle;
  integer requests_seen = 0;

  assign s_valid = response_valid;
  assign mem_read_data = response_data;

  fetch u_fetch(
    .mclk(mclk),
    .reset(reset),
    .sys_ready(sys_ready),
    .stall(1'b0),
    .ifid_flush(1'b0),
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .addr_i(addr_i),
    .mem_read_data(mem_read_data),
    .m_valid(m_valid),
    .s_valid(s_valid),
    .IFID_inst(IFID_inst),
    .IFID_pc(IFID_pc),
    .IFID_valid(IFID_valid),
    .ID_ready(ID_ready)
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

  // A one-stage response pipeline accepts a new request every clock.
  always @(posedge mclk) begin
    if (!reset) begin
      request_valid <= 1'b0;
      response_valid <= 1'b0;
      request_addr <= 32'b0;
      request_data <= 32'b0;
      response_addr <= 32'b0;
      response_data <= 32'b0;
    end else if (memory_enable) begin
      response_valid <= request_valid;
      if (request_valid) begin
        response_addr <= request_addr;
        response_data <= request_data;
      end
      request_valid <= m_valid;
      if (m_valid) begin
        request_addr <= addr_i;
        request_data <= instruction_mem[addr_i[7:2]];
      end
    end else begin
      request_valid <= 1'b0;
      response_valid <= 1'b0;
    end
  end

  // Check the streaming address against the last response consumed, then
  // match each returned word to the request from the preceding cycle.
  always @(posedge mclk) begin
    response_for_fetch = s_valid;
    checked_response_addr = response_addr;
    checked_response_data = response_data;

    if (reset && memory_enable) begin
      check(m_valid === 1'b1, "m_valid remains asserted across requests");
      check(addr_i === expected_request_addr,
            "request address advances after a valid response");
      requests_seen = requests_seen + 1;
      if (response_for_fetch) begin
        expected_request_addr = expected_request_addr + 32'd4;
        expected_ifid_pc = expected_ifid_pc + 32'd4;
      end
    end

    #1;
    if (reset && memory_enable) begin
      if (requests_seen > 1)
        check(s_valid === 1'b1, "memory returns one-cycle-latency responses every cycle");
      if (response_for_fetch) begin
        check(IFID_valid === 1'b1, "each response produces a valid IF/ID entry");
        check(checked_response_data === instruction_mem[checked_response_addr[7:2]],
          "memory response data matches its sampled request address");
        check(IFID_inst === checked_response_data,
              "IF/ID instruction matches its delayed memory response");
        check(IFID_pc === expected_ifid_pc,
          "IF/ID PC advances once for each valid response");
      end else begin
        check(IFID_valid === 1'b0, "IF/ID remains invalid while waiting for a response");
        check(IFID_pc === expected_ifid_pc, "IF/ID PC holds while waiting for a response");
      end
    end
  end

  initial begin
    $dumpfile("fetch.vcd");
    $dumpvars(0, fetch_tb);

    for (index = 0; index < 64; index = index + 1)
      instruction_mem[index] = 32'hA5000000 | index;

    repeat (2) @(posedge mclk);
    @(negedge mclk);
    reset = 1'b1;
    repeat (1) @(posedge mclk);
    @(negedge mclk);
    sys_ready = 1'b1;
    decoder_ready = 1'b1;
    memory_enable = 1'b1;

    for (cycle = 0; cycle < 12; cycle = cycle + 1)
      @(posedge mclk);

    @(negedge mclk);
    memory_enable = 1'b0;
    sys_ready = 1'b0;
    decoder_ready = 1'b0;
    #1;

    if (failures == 0) begin
      $display("fetch_tb: PASS (%0d checks)", checks);
      $finish;
    end else begin
      $display("fetch_tb: FAIL (%0d checks, %0d failures)", checks, failures);
      $fatal(1, "fetch_tb detected behavior that does not match the expected flow");
    end
  end
endmodule

