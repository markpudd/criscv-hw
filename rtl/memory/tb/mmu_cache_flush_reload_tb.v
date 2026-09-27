`timescale 1ns/1ps

// Hardware-oriented cache flush/reload test.
//
// A, B, and C share cache_set 0 but have different tags.  The sequence makes
// A dirty, fills B, then accesses C to force A out.  A must be written back
// to SDRAM before C is loaded; a later A access must reload the dirty value.
module mmu_cache_flush_reload_tb;
    localparam integer CLK_HALF = 5;
    localparam integer TIMEOUT_CYCLES = 800;
    localparam [1:0] SZ_WORD = 2'd2;

    localparam [31:0] ADDR_A = 32'h0001_0004;
    localparam [31:0] ADDR_B = 32'h0002_0004;
    localparam [31:0] ADDR_C = 32'h0003_0004;
    localparam [31:0] A_LINE = 32'h0001_0000;
    localparam [31:0] B_LINE = 32'h0002_0000;
    localparam [31:0] C_LINE = 32'h0003_0000;
    localparam [31:0] DIRTY_A = 32'hD1A7_C0DE;

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
    integer start_reads;
    integer start_writes;

    always #CLK_HALF clk = ~clk;

    mmu dut (
        .clk(clk), .reset(reset), .address(address), .rw(rw),
        .write_data(write_data), .size(size), .read_data(read_data),
        .m_valid(m_valid), .s_valid(s_valid), .sd_ce(sd_ce),
        .sd_address(sd_address), .sd_rw_req(sd_rw_req), .sd_rw(sd_rw),
        .sd_write_data(sd_write_data), .sd_burst_len(sd_burst_len),
        .sd_read_data(sd_read_data), .sd_data_bursting(sd_data_bursting)
    );

    // Abstract 16-bit SDRAM device.  Its array is intentionally visible in
    // the VCD so backing-memory changes can be inspected after writeback.
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

    function [31:0] backing_word;
        input [31:0] byte_address;
        integer halfword_index;
        begin
            halfword_index = byte_address >> 1;
            backing_word = {sdram[halfword_index + 1], sdram[halfword_index]};
        end
    endfunction

    task expect_backing_word;
        input [31:0] byte_address;
        input [31:0] expected;
        input [8*24:1] name;
        reg [31:0] got;
        begin
            got = backing_word(byte_address);
            if (got !== expected) begin
                $display("FAIL %0s backing=%08h expected=%08h", name, got, expected);
                errors = errors + 1;
            end else begin
                $display("PASS %0s backing=%08h", name, got);
            end
        end
    endtask

    task bus_access;
        input [31:0] request_address;
        input [1:0]  request_size;
        input        request_rw;
        input [31:0] request_data;
        input [31:0] expected;
        input [8*24:1] name;
        begin
            start_reads = read_beats;
            start_writes = write_beats;
            @(negedge clk);
            address = request_address;
            size = request_size;
            rw = request_rw;
            write_data = request_data;
            m_valid = 1'b1;
            cycles = 0;

            while (!s_valid && cycles < TIMEOUT_CYCLES) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end

            if (!s_valid) begin
                $display("FAIL %0s timeout addr=%08h state=%0d sd_req=%b sd_rw=%b",
                         name, request_address, dut.memcache.cState,
                         sd_rw_req, sd_rw);
                errors = errors + 1;
            end else if (!request_rw && read_data !== expected) begin
                $display("FAIL %0s data=%08h expected=%08h addr=%08h",
                         name, read_data, expected, request_address);
                errors = errors + 1;
            end else begin
                $display("PASS %0s data=%08h cycles=%0d reads=%0d writes=%0d",
                         name, read_data, cycles,
                         read_beats - start_reads, write_beats - start_writes);
            end

            @(negedge clk);
            m_valid = 1'b0;
            rw = 1'b0;
            size = SZ_WORD;
            #1;
        end
    endtask

    task expect_traffic;
        input integer expected_reads;
        input integer expected_writes;
        input [8*24:1] name;
        begin
            if ((read_beats - start_reads) !== expected_reads ||
                (write_beats - start_writes) !== expected_writes) begin
                $display("FAIL %0s traffic reads=%0d writes=%0d expected reads=%0d writes=%0d",
                         name, read_beats - start_reads,
                         write_beats - start_writes,
                         expected_reads, expected_writes);
                errors = errors + 1;
            end else begin
                $display("PASS %0s traffic reads=%0d writes=%0d",
                         name, read_beats - start_reads,
                         write_beats - start_writes);
            end
        end
    endtask

    initial begin
        for (i = 0; i < 131072; i = i + 1)
            sdram[i] = 16'h1000 + i[15:0];

        // Distinct values at the tested word in each line.
        sdram[(A_LINE >> 1) + 2] = 16'hA002;
        sdram[(A_LINE >> 1) + 3] = 16'hA003;
        sdram[(B_LINE >> 1) + 2] = 16'hB002;
        sdram[(B_LINE >> 1) + 3] = 16'hB003;
        sdram[(C_LINE >> 1) + 2] = 16'hC002;
        sdram[(C_LINE >> 1) + 3] = 16'hC003;

        $dumpfile("mmu_cache_flush_reload_tb.vcd");
        $dumpvars(0, mmu_cache_flush_reload_tb);

        repeat (4) @(negedge clk);
        reset = 1'b1;
        repeat (2) @(negedge clk);

        // Cold fill A.  A line fill is 32 halfwords; the controller may
        // expose one additional request beat while its burst terminates.
        bus_access(ADDR_A, SZ_WORD, 1'b0, 32'h0,
                   32'hA003_A002, "cold fill A");
        expect_traffic(33, 0, "cold fill A");

        // Hit A, then make the cached copy dirty without touching SDRAM.
        bus_access(ADDR_A, SZ_WORD, 1'b0, 32'h0,
                   32'hA003_A002, "hit A");
        expect_traffic(0, 0, "hit A");
        bus_access(ADDR_A, SZ_WORD, 1'b1, DIRTY_A,
                   DIRTY_A, "write dirty A");
        expect_traffic(0, 0, "write dirty A");
        bus_access(ADDR_A, SZ_WORD, 1'b0, 32'h0,
                   DIRTY_A, "read dirty A");
        expect_traffic(0, 0, "read dirty A");
        expect_backing_word(ADDR_A, 32'hA003_A002,
                            "backing A before eviction");

        // Fill B into the second way, then C must evict dirty A.
        bus_access(ADDR_B, SZ_WORD, 1'b0, 32'h0,
                   32'hB003_B002, "cold fill B");
        expect_traffic(33, 0, "cold fill B");
        bus_access(ADDR_C, SZ_WORD, 1'b0, 32'h0,
                   32'hC003_C002, "evict A and fill C");
        expect_traffic(33, 34, "evict A and fill C");
        expect_backing_word(ADDR_A, DIRTY_A,
                            "backing A after writeback");

        // A is gone from the cache.  This must reload the dirty value from
        // backing SDRAM, rather than return a stale or zero cache word.
        bus_access(ADDR_A, SZ_WORD, 1'b0, 32'h0,
                   DIRTY_A, "reload evicted A");
        expect_traffic(33, 0, "reload evicted A");

        // Verify the other way survived replacement and remains a hit.
        bus_access(ADDR_C, SZ_WORD, 1'b0, 32'h0,
                   32'hC003_C002, "hit C after A reload");
        expect_traffic(0, 0, "hit C after A reload");

        if (errors == 0)
            $display("PASS mmu_cache_flush_reload_tb");
        else
            $display("FAIL mmu_cache_flush_reload_tb errors=%0d (inspect mmu_cache_flush_reload_tb.vcd)", errors);
        $finish;
    end
endmodule