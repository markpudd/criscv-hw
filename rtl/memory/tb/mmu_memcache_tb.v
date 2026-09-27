`timescale 1ns/1ps

// MMU -> memcache -> 16-bit SDRAM-burst handshake test.
// The SDRAM array below is an abstract model of the controller-facing bus;
// use tb_mmu_sdram.v for a test including the pin-level SDRAM model.
module mmu_memcache_tb;
    localparam integer CLK_HALF = 5;
    localparam integer TIMEOUT_CYCLES = 300;
    localparam [1:0] SZ_WORD = 2'd2;
    localparam [31:0] TEST_ADDRESS = 32'h0001_0004;
    localparam integer SDRAM_WORD = (32'h0001_0000 >> 1);

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
    reg [31:0] result;

    always #CLK_HALF clk = ~clk;

    mmu dut (
        .clk(clk), .reset(reset), .address(address), .rw(rw),
        .write_data(write_data), .size(size), .read_data(read_data),
        .m_valid(m_valid), .s_valid(s_valid), .sd_ce(sd_ce),
        .sd_address(sd_address), .sd_rw_req(sd_rw_req), .sd_rw(sd_rw),
        .sd_write_data(sd_write_data), .sd_burst_len(sd_burst_len),
        .sd_read_data(sd_read_data), .sd_data_bursting(sd_data_bursting)
    );

    // One 16-bit beat is returned on each cycle requested by memcache.
    always @(negedge clk) begin
        sd_data_bursting = sd_rw_req;
        if (sd_rw_req) begin
            if (sd_rw)
                sdram[(sd_address >> 1) + burst_count] = sd_write_data;
            else
                sd_read_data = sdram[(sd_address >> 1) + burst_count];
        end else begin
            burst_count = 0;
        end
    end

    always @(posedge clk) begin
        if (sd_rw_req)
            burst_count = burst_count + 1;
    end

    task bus_op;
        input [31:0] request_address;
        input        request_rw;
        input [31:0] request_data;
        input [31:0] expected;
        begin
            @(posedge clk);
            address = request_address;
            rw = request_rw;
            write_data = request_data;
            size = SZ_WORD;
            m_valid = 1'b1;
            cycles = 0;
            while (!s_valid && cycles < TIMEOUT_CYCLES) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end
            if (!s_valid) begin
                $display("TIMEOUT %s addr=%08h busy=%b mem_req=%b state=%0d sd_req=%b bursts=%0d",
                         request_rw ? "WRITE" : "READ", request_address,
                         dut.memcache.busy, dut.mem_req, dut.memcache.cState,
                         sd_rw_req, burst_count);
                errors = errors + 1;
            end else if (read_data !== expected) begin
                $display("FAIL %s addr=%08h got=%08h expected=%08h cycles=%0d",
                         request_rw ? "WRITE" : "READ", request_address,
                         read_data, expected, cycles);
                errors = errors + 1;
            end else begin
                $display("PASS %s addr=%08h data=%08h cycles=%0d",
                         request_rw ? "WRITE" : "READ", request_address,
                         read_data, cycles);
            end
            @(posedge clk);
            m_valid = 1'b0;
            rw = 1'b0;
        end
    endtask

    initial begin
        for (i = 0; i < 131072; i = i + 1)
            sdram[i] = 16'h1000 + i[15:0];

        $dumpfile("mmu_memcache_tb.vcd");
        $dumpvars(0, mmu_memcache_tb);

        repeat (3) @(posedge clk);
        reset = 1'b1;

        // 0x10004 is the second 32-bit word in the line:
        // {halfword 0x9003, halfword 0x9002}.
        bus_op(TEST_ADDRESS, 1'b0, 32'h0, 32'h9003_9002);
        bus_op(TEST_ADDRESS, 1'b0, 32'h0, 32'h9003_9002);
        bus_op(TEST_ADDRESS, 1'b1, 32'hDEAD_BEEF, 32'hDEAD_BEEF);
        bus_op(TEST_ADDRESS, 1'b0, 32'h0, 32'hDEAD_BEEF);

        if (errors == 0)
            $display("PASS mmu_memcache_tb");
        else
            $display("FAIL mmu_memcache_tb errors=%0d (inspect mmu_memcache_tb.vcd)", errors);
        $finish;
    end
endmodule