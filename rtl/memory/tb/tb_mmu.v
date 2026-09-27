//==========================================================================
// tb_mmu.v -- self-checking testbench for mmu.v (Icarus Verilog / Verilog-2001)
//
//   iverilog -g2005 -o mmu_tb tb_mmu.v mmu.v sim_models/ram.v sim_models/memcache.v
//   vvp mmu_tb
//
// Plusargs:
//   +vcd        write mmu_tb.vcd for GTKWave
//   +strict     hold m_valid asserted through the cycle s_valid is sampled
//               high, dropping it one cycle later instead of inside that
//               same cycle -- checks the DUT survives a master that reacts
//               one cycle late to completion.
//   +verbose    print every transaction
//
// What this assumes about the current mmu.v contract (2-signal handshake):
//   * m_valid + address/size/rw/write_data are held stable by the master
//     for the whole transaction; the master may not change them while
//     m_valid=1 and s_valid=0.
//   * s_valid is a single-cycle COMPLETION strobe (cState==DONE && m_valid),
//     not a registered/latched done flag -- read_data is only guaranteed
//     valid during that one cycle.
//   * There is no separate ready/backpressure signal in either direction:
//     m_valid is the whole request side of the handshake and s_valid is the
//     whole response side. (Earlier revisions of this DUT also had m_ready/
//     s_ready ports; those are gone now that the interface is just the two
//     signals, so the tests that exercised them have been removed below.)
//==========================================================================
`timescale 1ns/1ps

module tb_mmu;

    //----------------------------------------------------------------------
    // Parameters / constants
    //----------------------------------------------------------------------
    localparam CLK_HALF  = 5;      // 100 MHz cpu/cache clock
    localparam MCLK_HALF = 2;      // faster memory clock (unused by stubs)
    localparam TIMEOUT   = 300;    // clocks before a transaction is declared hung

    localparam [1:0] SZ_BYTE = 2'd0,
                     SZ_HALF = 2'd1,
                     SZ_WORD = 2'd2;

    localparam [31:0] RAM_BASE   = 32'h0000_0400;   // local block RAM region
    localparam [31:0] CACHE_BASE = 32'h0001_0400;   // memcache / SDRAM region

    //----------------------------------------------------------------------
    // DUT nets
    //----------------------------------------------------------------------
    reg         clk   = 1'b0;
    reg         mclk  = 1'b0;
    reg         reset = 1'b0;      // active LOW

    reg  [31:0] address     = 32'h0;
    reg         rw          = 1'b0;
    reg  [31:0] write_data  = 32'h0;
    reg  [1:0]  size        = SZ_WORD;
    reg         m_valid     = 1'b0;   // master request valid

    wire [31:0] read_data;
    wire        s_valid;              // slave completion strobe

    wire        sd_ce;
    wire [31:0] sd_address;
    wire        sd_rw_req;
    wire        sd_rw;
    wire [15:0] sd_write_data;
    wire [7:0]  sd_burst_len;
    reg  [15:0] sd_read_data     = 16'h0;
    reg         sd_data_bursting = 1'b0;

    //----------------------------------------------------------------------
    // Bookkeeping
    //----------------------------------------------------------------------
    integer checks      = 0;
    integer errors      = 0;
    integer warnings    = 0;
    integer proto_viol  = 0;
    integer verbose     = 0;
    integer strict      = 0;
    integer do_vcd      = 0;
    integer mon_en      = 0;

    reg [31:0] rdata;
    reg [31:0] tmp;
    integer    t;
    reg        got_ready;

    //----------------------------------------------------------------------
    // Clocks
    //----------------------------------------------------------------------
    always #CLK_HALF  clk  = ~clk;
    always #MCLK_HALF mclk = ~mclk;

    //----------------------------------------------------------------------
    // DUT
    //----------------------------------------------------------------------
    mmu dut (
        .clk              (clk),
        .mclk             (mclk),
        .reset            (reset),
        .address          (address),
        .rw               (rw),
        .write_data       (write_data),
        .size             (size),
        .read_data        (read_data),
        .m_valid          (m_valid),
        .s_valid          (s_valid),
        .sd_ce            (sd_ce),
        .sd_address       (sd_address),
        .sd_rw_req        (sd_rw_req),
        .sd_rw            (sd_rw),
        .sd_write_data    (sd_write_data),
        .sd_burst_len     (sd_burst_len),
        .sd_read_data     (sd_read_data),
        .sd_data_bursting (sd_data_bursting)
    );

    //----------------------------------------------------------------------
    // Reporting helpers
    //----------------------------------------------------------------------
    task check;
        input [8*48:1] name;
        input [31:0]   got;
        input [31:0]   exp;
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("  FAIL  %0s : got %08h expected %08h   (t=%0t)",
                         name, got, exp, $time);
            end else if (verbose) begin
                $display("  ok    %0s : %08h", name, got);
            end
        end
    endtask

    task warn;
        input [8*110:1] msg;
        begin
            warnings = warnings + 1;
            $display("  WARN  %0s   (t=%0t)", msg, $time);
        end
    endtask

    task banner;
        input [8*64:1] msg;
        begin
            $display("");
            $display("--- %0s ---", msg);
        end
    endtask

    //----------------------------------------------------------------------
    // Bus master model
    //
    // keep_valid=1 leaves m_valid asserted on exit so the next call can be
    // issued back to back without an idle cycle.
    //----------------------------------------------------------------------
    task bus_op;
        input [31:0] a;
        input [1:0]  sz;
        input        is_write;
        input [31:0] wd;
        input        keep_valid;
        output [31:0] rd;
        begin
            @(negedge clk);
            address    = a;
            size       = sz;
            rw         = is_write;
            write_data = wd;
            m_valid    = 1'b1;

            rd        = 32'hxxxx_xxxx;
            got_ready = 1'b0;
            t         = 0;

            while (!got_ready && t < TIMEOUT) begin
                @(posedge clk);
                #1;
                if (s_valid === 1'b1) begin
                    rd        = read_data;
                    got_ready = 1'b1;
                end
                t = t + 1;
            end

            if (!got_ready) begin
                errors = errors + 1;
                $display("  FAIL  TIMEOUT: no s_valid for %0s addr=%08h size=%0d  (t=%0t)",
                         is_write ? "WR" : "RD", a, sz, $time);
            end

            // A master that reacts one cycle late samples s_valid on the
            // rising edge and only then drops m_valid on the following
            // negedge, instead of dropping it inside the same s_valid cycle.
            if (strict) @(posedge clk);

            if (!keep_valid) begin
                @(negedge clk);
                m_valid = 1'b0;
                rw      = 1'b0;
            end
        end
    endtask

    task bus_write;
        input [31:0] a;
        input [1:0]  sz;
        input [31:0] d;
        begin
            bus_op(a, sz, 1'b1, d, 1'b0, tmp);
        end
    endtask

    task bus_read;
        input [31:0] a;
        input [1:0]  sz;
        output [31:0] d;
        begin
            bus_op(a, sz, 1'b0, 32'h0, 1'b0, d);
        end
    endtask

    //----------------------------------------------------------------------
    // Handshake monitor (sampled on negedge so everything has settled).
    // Reports, never fails the run.
    //----------------------------------------------------------------------
    reg        prev_m_valid   = 1'b0;
    reg [31:0] prev_addr      = 32'h0;
    reg        seen_addr_move = 1'b0;

    always @(negedge clk) begin
        if (reset === 1'b1 && mon_en) begin
            // R1: request payload (address/rw/write_data/size) must stay
            // stable while m_valid is asserted and the slave hasn't
            // completed the transaction yet.
            if (prev_m_valid && m_valid && !s_valid &&
                (prev_addr !== address) && !seen_addr_move) begin
                proto_viol = proto_viol + 1;
                seen_addr_move = 1'b1;
                $display("  PROTO testbench changed address mid-transaction (t=%0t)", $time);
            end
        end
        prev_m_valid <= m_valid;
        prev_addr    <= address;
    end

    //----------------------------------------------------------------------
    // Functional suite, run once per memory region
    //----------------------------------------------------------------------
    task run_suite;
        input [31:0] base;
        reg [31:0] rd;
        begin
            // --- aligned word
            bus_write(base + 32'h00, SZ_WORD, 32'hDEADBEEF);
            bus_read (base + 32'h00, SZ_WORD, rd);
            check("word  @+0x00 (even, 2 beats)", rd, 32'hDEADBEEF);

            // --- word at an even but non-word-aligned offset
            bus_write(base + 32'h22, SZ_WORD, 32'hCAFEF00D);
            bus_read (base + 32'h22, SZ_WORD, rd);
            check("word  @+0x22 (even, 2 beats)", rd, 32'hCAFEF00D);

            // --- word straddling an odd byte -> 3 beats
            bus_write(base + 32'h11, SZ_WORD, 32'h01234567);
            bus_read (base + 32'h11, SZ_WORD, rd);
            check("word  @+0x11 (odd, 3 beats)", rd, 32'h01234567);

            // --- halfwords
            bus_write(base + 32'h30, SZ_HALF, 32'h0000BEEF);
            bus_read (base + 32'h30, SZ_HALF, rd);
            check("half  @+0x30 (even, 1 beat)", rd, 32'h0000BEEF);

            bus_write(base + 32'h41, SZ_HALF, 32'h0000A55A);
            bus_read (base + 32'h41, SZ_HALF, rd);
            check("half  @+0x41 (odd, 2 beats)", rd, 32'h0000A55A);

            // --- bytes
            bus_write(base + 32'h50, SZ_BYTE, 32'h00000042);
            bus_read (base + 32'h50, SZ_BYTE, rd);
            check("byte  @+0x50 (even)", rd, 32'h00000042);

            bus_write(base + 32'h51, SZ_BYTE, 32'h000000A7);
            bus_read (base + 32'h51, SZ_BYTE, rd);
            check("byte  @+0x51 (odd)", rd, 32'h000000A7);

            // --- endianness: word in, bytes out (RISC-V is little endian)
            bus_write(base + 32'h60, SZ_WORD, 32'h11223344);
            bus_read (base + 32'h60, SZ_BYTE, rd); check("LE byte0 of 11223344", rd, 32'h44);
            bus_read (base + 32'h61, SZ_BYTE, rd); check("LE byte1 of 11223344", rd, 32'h33);
            bus_read (base + 32'h62, SZ_BYTE, rd); check("LE byte2 of 11223344", rd, 32'h22);
            bus_read (base + 32'h63, SZ_BYTE, rd); check("LE byte3 of 11223344", rd, 32'h11);
            bus_read (base + 32'h60, SZ_HALF, rd); check("LE half0 of 11223344", rd, 32'h3344);
            bus_read (base + 32'h62, SZ_HALF, rd); check("LE half1 of 11223344", rd, 32'h1122);

            // --- bytes in, word out
            bus_write(base + 32'h70, SZ_BYTE, 32'h000000AA);
            bus_write(base + 32'h71, SZ_BYTE, 32'h000000BB);
            bus_write(base + 32'h72, SZ_BYTE, 32'h000000CC);
            bus_write(base + 32'h73, SZ_BYTE, 32'h000000DD);
            bus_read (base + 32'h70, SZ_WORD, rd);
            check("word from four byte writes", rd, 32'hDDCCBBAA);

            // --- odd halfword writes, word readback
            bus_write(base + 32'h81, SZ_HALF, 32'h00001234);
            bus_write(base + 32'h83, SZ_HALF, 32'h00005678);
            bus_read (base + 32'h81, SZ_WORD, rd);
            check("word from two odd half writes", rd, 32'h56781234);

            // --- byte enables must not corrupt neighbours
            bus_write(base + 32'h90, SZ_WORD, 32'hFFFFFFFF);
            bus_write(base + 32'h94, SZ_WORD, 32'h00000000);
            bus_write(base + 32'h91, SZ_BYTE, 32'h0000005A);
            bus_read (base + 32'h90, SZ_WORD, rd);
            check("byte write inside a word", rd, 32'hFFFF5AFF);
            bus_read (base + 32'h94, SZ_WORD, rd);
            check("adjacent word untouched", rd, 32'h00000000);

            // --- upper bits of read_data must be zero-extended
            bus_write(base + 32'hA0, SZ_WORD, 32'hFFFFFFFF);
            bus_read (base + 32'hA0, SZ_BYTE, rd);
            check("byte read zero-extends", rd, 32'h000000FF);
            bus_read (base + 32'hA0, SZ_HALF, rd);
            check("half read zero-extends", rd, 32'h0000FFFF);
        end
    endtask

    //----------------------------------------------------------------------
    // Stimulus
    //----------------------------------------------------------------------
    integer spurious_at_start;

    initial begin
        if ($test$plusargs("verbose")) verbose = 1;
        if ($test$plusargs("strict"))  strict  = 1;
        if ($test$plusargs("vcd"))     do_vcd  = 1;

        if (do_vcd) begin
            $dumpfile("mmu_tb.vcd");
            $dumpvars(0, tb_mmu);
        end

        $display("========================================================");
        $display(" mmu.v testbench   strict_late_master=%0d", strict);
        $display("========================================================");

        // reset
        reset   = 1'b0;
        m_valid = 1'b0;
        repeat (5) @(negedge clk);
        reset = 1'b1;
        repeat (3) @(negedge clk);
        mon_en = 1;

        //------------------------------------------------------------------
        banner("A. Local block RAM region (ce=0, base 0x00000400)");
        run_suite(RAM_BASE);

        //------------------------------------------------------------------
        banner("B. memcache / SDRAM region (ce=1, base 0x00010400)");
        spurious_at_start = dut.memcache.spurious_reqs;
        run_suite(CACHE_BASE);

        //------------------------------------------------------------------
        banner("C. Physical layout in the block RAM");
        // byte address 2n lives in q[15:8], 2n+1 in q[7:0]
        bus_write(RAM_BASE + 32'hC0, SZ_WORD, 32'h89ABCDEF);
        check("RAM byte +0xC0", {24'h0, dut.ram.peek_byte(RAM_BASE + 32'hC0)}, 32'h000000EF);
        check("RAM byte +0xC1", {24'h0, dut.ram.peek_byte(RAM_BASE + 32'hC1)}, 32'h000000CD);
        check("RAM byte +0xC2", {24'h0, dut.ram.peek_byte(RAM_BASE + 32'hC2)}, 32'h000000AB);
        check("RAM byte +0xC3", {24'h0, dut.ram.peek_byte(RAM_BASE + 32'hC3)}, 32'h00000089);
        $display("  NOTE  a boot.hex loaded with $readmemh must store byte 2n in bits [15:8].");

        //------------------------------------------------------------------
        banner("D. Back-to-back transactions with m_valid held high");
        bus_write(RAM_BASE + 32'hD0, SZ_WORD, 32'h0BADF00D);
        bus_write(RAM_BASE + 32'hD4, SZ_WORD, 32'hFEEDFACE);
        // op 1, valid stays asserted into op 2
        bus_op(RAM_BASE + 32'hD0, SZ_WORD, 1'b0, 32'h0, 1'b1, rdata);
        check("b2b read 1", rdata, 32'h0BADF00D);
        bus_op(RAM_BASE + 32'hD4, SZ_WORD, 1'b0, 32'h0, 1'b0, rdata);
        check("b2b read 2", rdata, 32'hFEEDFACE);
        // NOTE: with the current cState/nState FSM, DONE only returns to
        // IDLE when m_valid drops (see the "DONE" case in mmu.v's next-state
        // logic). Holding m_valid asserted across two bus_op calls (as
        // keep_valid=1 does here) means cState never leaves DONE between
        // them, so op 2 may just re-observe op 1's already-latched
        // read_data rather than launching a fresh access for the new
        // address. If "b2b read 2" starts failing once the DUT bugs are
        // fixed and this compiles cleanly, that FSM behaviour -- not this
        // testbench -- is the first place to look.

        //------------------------------------------------------------------
        banner("E. read_data lifetime after s_valid");
        bus_op(RAM_BASE + 32'hD4, SZ_WORD, 1'b0, 32'h0, 1'b0, rdata);
        check("value at s_valid", rdata, 32'hFEEDFACE);
        @(posedge clk); #1;
        if (read_data !== 32'hFEEDFACE)
            warn("read_data is not held one clock after s_valid -- it is only valid during the s_valid pulse");

        //------------------------------------------------------------------
        banner("F. Address decode / aliasing probe");
        bus_write(32'h0000_0100, SZ_WORD, 32'h11111111);
        bus_write(32'h0000_8100, SZ_WORD, 32'h22222222);
        bus_read (32'h0000_0100, SZ_WORD, rdata);
        if (rdata === 32'h22222222)
            warn("0x8100 aliases onto 0x0100 -- ce/cel split at 0x10000 but RAM is only 32KB");
        else
            check("no aliasing between 0x0100 and 0x8100", rdata, 32'h11111111);

        //------------------------------------------------------------------
        banner("G. Spurious memcache requests during local RAM access");
        spurious_at_start = dut.memcache.spurious_reqs;
        bus_write(RAM_BASE + 32'hE0, SZ_WORD, 32'h5A5A5A5A);
        bus_read (RAM_BASE + 32'hE0, SZ_WORD, rdata);
        check("local RAM word", rdata, 32'h5A5A5A5A);
        if (dut.memcache.spurious_reqs > spurious_at_start)
            warn("mem_req reached memcache with ce=0 -- mem_req is not gated by ce");

        //------------------------------------------------------------------
        banner("H. Peripheral space (address[31]=1) is never acknowledged");
        @(negedge clk);
        address = 32'h8000_0000;
        size    = SZ_WORD;
        rw      = 1'b0;
        m_valid = 1'b1;
        t = 0;
        got_ready = 1'b0;
        while (!got_ready && t < 40) begin
            @(posedge clk); #1;
            if (s_valid === 1'b1) got_ready = 1'b1;
            t = t + 1;
        end
        @(negedge clk);
        m_valid = 1'b0;
        if (!got_ready)
            warn("address[31]=1 produces no s_valid -- the CPU will hang unless decoded upstream");

        //------------------------------------------------------------------
        banner("I. Reset behaviour mid-transaction");
        @(negedge clk);
        address = RAM_BASE + 32'h11;
        size    = SZ_WORD;
        rw      = 1'b0;
        m_valid = 1'b1;
        repeat (4) @(negedge clk);
        reset   = 1'b0;
        repeat (3) @(negedge clk);
        m_valid = 1'b0;
        reset   = 1'b1;
        repeat (3) @(negedge clk);
        bus_read(RAM_BASE + 32'hD4, SZ_WORD, rdata);
        check("bus usable after mid-op reset", rdata, 32'hFEEDFACE);

        //------------------------------------------------------------------
        repeat (5) @(negedge clk);
        $display("");
        $display("========================================================");
        $display(" checks   : %0d", checks);
        $display(" failures : %0d", errors);
        $display(" warnings : %0d", warnings);
        $display(" protocol : %0d handshake deviations", proto_viol);
        $display(" memcache : %0d beats served, %0d clocks with rw_req while ce=0",
                 dut.memcache.beats_served, dut.memcache.spurious_reqs);
        if (errors == 0) $display(" RESULT   : PASS (functional)");
        else             $display(" RESULT   : FAIL");
        $display("========================================================");
        $finish;
    end

    // global watchdog
    initial begin
        #500000;
        $display("*** GLOBAL TIMEOUT -- simulation hung ***");
        $finish;
    end

endmodule
