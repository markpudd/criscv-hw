`timescale 1ns/1ps

module mmu_dual_request_tb;
    localparam integer TIMEOUT_CYCLES = 20;

    reg clk = 1'b0;
    reg reset = 1'b0;
    reg [11:0] inst_addr = 12'b0;
    reg inst_en = 1'b0;
    reg inst_m_valid = 1'b0;
    wire [31:0] inst_out;
    wire inst_s_valid;
    reg [11:0] data_addr = 12'b0;
    reg [31:0] data_in = 32'b0;
    reg data_en = 1'b0;
    reg data_we = 1'b0;
    reg [1:0] data_size = 2'b10;
    reg data_m_valid = 1'b0;
    wire [31:0] data_out;
    wire data_s_valid;
    wire sd_ce;
    wire [31:0] sd_address;
    wire sd_rw_req;
    wire sd_rw;
    wire [15:0] sd_write_data;
    wire [7:0] sd_burst_len;
    reg [15:0] sd_read_data = 16'b0;
    reg sd_data_bursting = 1'b0;

    integer cycles;

    always #5 clk = ~clk;

    mmu dut (
        .clk(clk),
        .reset(reset),
        .inst_addr(inst_addr),
        .inst_en(inst_en),
        .inst_out(inst_out),
        .inst_m_valid(inst_m_valid),
        .inst_s_valid(inst_s_valid),
        .data_addr(data_addr),
        .data_in(data_in),
        .data_en(data_en),
        .data_we(data_we),
        .data_out(data_out),
        .data_size(data_size),
        .data_m_valid(data_m_valid),
        .data_s_valid(data_s_valid),
        .sd_ce(sd_ce),
        .sd_address(sd_address),
        .sd_rw_req(sd_rw_req),
        .sd_rw(sd_rw),
        .sd_write_data(sd_write_data),
        .sd_burst_len(sd_burst_len),
        .sd_read_data(sd_read_data),
        .sd_data_bursting(sd_data_bursting)
    );

    initial begin
        repeat (3) @(negedge clk);
        reset = 1'b1;

        // Both requests arrive together; the data-side request must win.
        @(negedge clk);
        inst_addr = 12'h123;
        inst_en = 1'b1;
        inst_m_valid = 1'b1;
        data_addr = 12'h040;
        data_en = 1'b1;
        data_m_valid = 1'b1;

        @(posedge clk);
        #1;
        if (!dut.m_valid || !dut.owner_d || dut.mem_address[11:0] !== data_addr)
            $fatal(1, "data request did not win simultaneous arbitration");

        cycles = 0;
        while (!data_s_valid && cycles < TIMEOUT_CYCLES) begin
            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end
        if (!data_s_valid)
            $fatal(1, "timed out waiting for data-side completion");
        if (inst_s_valid)
            $fatal(1, "instruction side completed the data-side request");

        // Keep both requester valids asserted through the data completion
        // edge, as synchronous requesters do until they observe the response.
        @(negedge clk);
        if (!data_s_valid || inst_s_valid)
            $fatal(1, "data-side completion was not routed to its owner");

        @(posedge clk);
        #1;
        if (!inst_s_valid || data_s_valid)
            $fatal(1, "instruction request was not serviced after data completion");
        if (!dut.m_valid)
            $fatal(1, "memory valid dropped between consecutive requests");
        if (dut.owner_d || dut.mem_address[11:0] !== inst_addr)
            $fatal(1, "instruction request was not selected for the next transaction");

        @(negedge clk);
        data_m_valid = 1'b0;
        @(posedge clk);
        #1;
        if (dut.m_valid)
            $fatal(1, "memory valid did not clear after all requests completed");
        if (inst_s_valid || data_s_valid)
            $fatal(1, "completion was routed to a requester after its transaction ended");

        $display("PASS mmu_dual_request_tb");
        $finish;
    end

    initial begin
        #500;
        $fatal(1, "testbench watchdog expired");
    end
endmodule
