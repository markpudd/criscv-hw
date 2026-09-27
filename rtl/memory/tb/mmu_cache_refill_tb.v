`timescale 1ns/1ps

// MMU cache replacement/refill test.
// A, B, and C have the same cache set but different tags:
//   A = 0x00010004, B = 0x00020004, C = 0x00030004.
// The sequence A, B, C, A fills both ways, replaces A with C, then refills A.
module mmu_cache_refill_tb;
    localparam integer CLK_HALF = 5;
    localparam integer TIMEOUT_CYCLES = 500;
    localparam [1:0] SZ_WORD = 2'd2;

    localparam [31:0] ADDR_A = 32'h0001_0004;
    localparam [31:0] ADDR_B = 32'h0002_0004;
    localparam [31:0] ADDR_C = 32'h0003_0004;

    reg         clk = 1'b0;
    reg         reset = 1'b0;
    reg  [31:0] address = 32'h0;
    reg         rw = 1'b0;
    reg  [31:0] write_data = 32'h0;
    reg  [1:0]  size = SZ_WORD;
    reg         m_valid = 1'b0;

    wire [31:0] read_data;
    wire        s_valid;
    wire        sd_ce;
    wire [31:0] sd_address;
    wire        sd_rw_req;
    wire        sd_rw;
    wire [15:0] sd_write_data;
    wire [7:0]  sd_burst_len;
    reg  [15:0] sd_read_data = 16'h0;
    reg         sd_data_bursting = 1'b0;

    reg [15:0] sdram [0:131071];
    integer i;
    integer cycles;
    integer errors = 0;
    integer burst_count = 0;
    integer read_beats = 0;
    integer write_beats = 0;
    integer operation_reads;
    integer operation_writes;

    always #CLK_HALF clk = ~clk;

    mmu dut (
        .clk(clk), .reset(reset), .address(address), .rw(rw),
        .write_data(write_data), .size(size), .read_data(read_data),
        .m_valid(m_valid), .s_valid(s_valid), .sd_ce(sd_ce),
        .sd_address(sd_address), .sd_rw_req(sd_rw_req), .sd_rw(sd_rw),
        .sd_write_data(sd_write_data), .sd_burst_len(sd_burst_len),
        .sd_read_data(sd_read_data), .sd_data_bursting(sd_data_bursting)
    );

    // Abstract SDRAM device on the same 16-bit burst interface used by memcache.
    always @(negedge clk) begin
        sd_data_bursting = sd_rw_req;
        if (sd_rw_req) begin
            if (sd_rw) begin
                sdram[(sd_address >> 1) + burst_count] = sd_write_data;
                write_beats = write_beats + 1;
            end else begin
                sd_read_data = sdram[(sd_address >> 1) + burst_count];
                read_beats = read_beats + 1;
            end
        end else begin
            burst_count = 0;
        end
    end

    always @(posedge clk) begin
        if (sd_rw_req)
            burst_count = burst_count + 1;
    end

    task cache_read;
        input [31:0] request_address;
        input [31:0] expected;
        input [8*16:1] name;
        begin
            operation_reads = read_beats;
            operation_writes = write_beats;
            @(negedge clk);
            address = request_address;
            rw = 1'b0;
            write_data = 32'h0;
            size = SZ_WORD;
            m_valid = 1'b1;
            cycles = 0;

            while (!s_valid && cycles < TIMEOUT_CYCLES) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end

            if (!s_valid) begin
                $display("TIMEOUT %0s addr=%08h state=%0d mem_req=%b sd_req=%b",
                         name, request_address, dut.memcache.cState,
                         dut.mem_req, sd_rw_req);
                errors = errors + 1;
            end else if (read_data !== expected) begin
                $display("FAIL %0s addr=%08h got=%08h expected=%08h",
                         name, request_address, read_data, expected);
                errors = errors + 1;
            end else begin
                $display("PASS %0s addr=%08h data=%08h cycles=%0d",
                         name, request_address, read_data, cycles);
            end

            @(negedge clk);
            m_valid = 1'b0;
            rw = 1'b0;
            #1;
            $display("       SDRAM traffic for %0s: reads=%0d writes=%0d",
                     name, read_beats - operation_reads,
                     write_beats - operation_writes);
            if (request_address == ADDR_C &&
                write_beats == operation_writes) begin
                $display("FAIL %0s: replacement produced no SDRAM writeback", name);
                errors = errors + 1;
            end
        end
    endtask

    function [31:0] expected_word;
        input [31:0] line_address;
        integer base;
        begin
            base = line_address >> 1;
            expected_word = {sdram[base + 3], sdram[base + 2]};
        end
    endfunction

    task check_sdram_reads;
        input integer before_reads;
        input [8*16:1] name;
        begin
            if (read_beats == before_reads) begin
                $display("FAIL %0s: no SDRAM read burst observed", name);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        for (i = 0; i < 131072; i = i + 1)
            sdram[i] = 16'h1000 + i[15:0];

        // Keep the three replacement lines distinguishable despite the
        // 16-bit SDRAM data width and the array's 16-bit address wrap.
        sdram[(32'h0001_0000 >> 1) + 2] = 16'hA002;
        sdram[(32'h0001_0000 >> 1) + 3] = 16'hA003;
        sdram[(32'h0002_0000 >> 1) + 2] = 16'hB002;
        sdram[(32'h0002_0000 >> 1) + 3] = 16'hB003;
        sdram[(32'h0003_0000 >> 1) + 2] = 16'hC002;
        sdram[(32'h0003_0000 >> 1) + 3] = 16'hC003;

        $dumpfile("mmu_cache_refill_tb.vcd");
        $dumpvars(0, mmu_cache_refill_tb);

        repeat (4) @(negedge clk);
        reset = 1'b1;
        repeat (2) @(negedge clk);

        operation_reads = read_beats;
            cache_read(ADDR_A, 32'hA003_A002, "fill A");
            cache_read(ADDR_A, 32'hA003_A002, "hit A");
            cache_read(ADDR_B, 32'hB003_B002, "fill B");
            cache_read(ADDR_C, 32'hC003_C002, "replace A with C");
            cache_read(ADDR_A, 32'hA003_A002, "refill evicted A");

        if (errors == 0)
            $display("PASS mmu_cache_refill_tb");
        else
            $display("FAIL mmu_cache_refill_tb errors=%0d (inspect mmu_cache_refill_tb.vcd)", errors);
        $finish;
    end

    always @(posedge clk) begin
        if (m_valid && dut.memcache.cState != dut.memcache.nState)
            $display("TRACE addr=%08h state=%0d next=%0d way0=%08h way1=%08h replace=%b sd_req=%b sd_rw=%b",
                     address, dut.memcache.cState, dut.memcache.nState,
                     dut.memcache.cl_q[0], dut.memcache.cl_q[1],
                     dut.memcache.replace_index, sd_rw_req, sd_rw);
    end
endmodule