/*
 * mmu_sim_model.v
 *
 * Simple, well-behaved behavioural memory model exposing the same
 * master-facing interface as the real "mmu" module, for exercising your
 * pipeline stages in isolation before hooking them up to the real MMU/cache.
 *
 * Protocol (matches what the real MMU expects/produces):
 *   - Master drives address/rw/write_data/size and asserts m_valid.
 *   - Master MUST hold address/rw/write_data/size and m_valid steady until
 *     it observes s_valid==1 (this model latches the request on acceptance,
 *     so it will not itself get confused if m_valid drops early -- but see
 *     WARN_ON_EARLY_DEASSERT below, which is there specifically to help you
 *     catch a pipeline that doesn't hold m_valid for the full transaction,
 *     since that exact bug is what broke the real MMU's multi-cycle writes).
 *   - This model asserts s_valid for as long as it sits in DONE, i.e. until
 *     the master drops m_valid. read_data is valid while s_valid is high.
 *   - rw: 1 = write, 0 = read.
 *   - size: 2'b00 = byte, 2'b01 = halfword, 2'b10 = word (2'b11 unused,
 *     treated as word).
 *   - Byte order is little-endian (byte 0 of a word is the LSB), matching
 *     RISC-V. Accesses may be arbitrarily misaligned -- this model does not
 *     need the byte-lane gymnastics the real MMU needs for a 16-bit-wide
 *     physical memory, since it's just a behavioural reference.
 *
 * Timing:
 *   - Every transaction takes RESP_LATENCY+1 clock cycles from acceptance
 *     (the cycle m_valid is seen in IDLE) to the cycle s_valid first goes
 *     high. RESP_LATENCY=0 still costs one cycle -- nothing here is
 *     zero-latency/combinational, matching a real synchronous memory.
 *   - Once accepted, the transaction runs to completion regardless of what
 *     the master does with m_valid afterwards (this model does not
 *     reproduce the deadlock bug the real MMU had -- it's meant to be a
 *     correct reference, not a bug-for-bug clone).
 *
 * Testbench pokes:
 *   - poke_byte/poke_half/poke_word write memory directly, bypassing the
 *     m_valid/s_valid protocol entirely -- call them as hierarchical task
 *     calls from your testbench, e.g. dut.poke_word(32'h100, 32'hDEAD_BEEF);
 *   - peek_byte/peek_half/peek_word read memory back the same way, e.g.
 *     if (dut.peek_word(32'h100) !== 32'hDEAD_BEEF) ...
 *   - poke_fill fills a byte range with a repeating value.
 *   - load_hex_file re-loads memory at runtime from a $readmemh-format file
 *     (on top of, or instead of, the MEM_INIT_FILE parameter).
 *   All of these are immediate/blocking -- call them from an initial block
 *   before you start driving m_valid, or during an idle gap between
 *   transactions, so you don't race the DUT's own access in the same cycle.
 */

module mmu_sim_model #(
    parameter MEM_BYTES              = 65536,  // memory size in bytes
    parameter RESP_LATENCY           = 2,       // extra wait cycles after acceptance (>=0)
    parameter MEM_INIT_FILE          = "",      // optional $readmemh file to preload memory
    parameter WARN_ON_EARLY_DEASSERT = 1        // sim-only: $display a warning if m_valid
                                                 // drops before s_valid goes high
) (
    input             mclk,
    input             reset,        // active-low, same polarity as the real mmu

    input      [31:0] address,
    input             rw,           // 1 = write, 0 = read
    input      [31:0] write_data,
    input      [1:0]  size,
    output reg [31:0] read_data,

    input             m_valid,      // master valid
    output            s_valid       // slave valid
);

    localparam S_IDLE = 2'd0,
               S_WAIT = 2'd1,
               S_DONE = 2'd2;

    reg [1:0]  state;
    reg [31:0] latch_addr;
    reg        latch_rw;
    reg [31:0] latch_wdata;
    reg [1:0]  latch_size;
    reg [31:0] wait_cnt;

    reg [7:0] mem [0:MEM_BYTES-1];

    generate
        if (MEM_INIT_FILE != "") begin : init_mem
            initial $readmemh(MEM_INIT_FILE, mem);
        end
    endgenerate

    assign s_valid = (state == S_DONE);

    // --- state machine -----------------------------------------------
    always @(posedge mclk) begin
        if (~reset) begin
            state    <= S_IDLE;
            wait_cnt <= 32'h0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (m_valid) begin
                        latch_addr  <= address;
                        latch_rw    <= rw;
                        latch_wdata <= write_data;
                        latch_size  <= size;
                        wait_cnt    <= RESP_LATENCY;
                        state       <= S_WAIT;
                    end
                end

                S_WAIT: begin
                    if (wait_cnt == 32'h0)
                        state <= S_DONE;
                    else
                        wait_cnt <= wait_cnt - 32'h1;
                end

                S_DONE: begin
                    if (!m_valid)
                        state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // --- the actual memory access, performed exactly once, on the ------
    // --- S_WAIT -> S_DONE transition -----------------------------------
    always @(posedge mclk) begin
        if (~reset) begin
            read_data <= 32'h0;
        end else if (state == S_WAIT && wait_cnt == 32'h0) begin
            if (latch_rw) begin
                case (latch_size)
                    2'd0: begin
                        mem[latch_addr[$clog2(MEM_BYTES)-1:0]] <= latch_wdata[7:0];
                    end
                    2'd1: begin
                        mem[latch_addr[$clog2(MEM_BYTES)-1:0]]     <= latch_wdata[7:0];
                        mem[latch_addr[$clog2(MEM_BYTES)-1:0]+1]   <= latch_wdata[15:8];
                    end
                    default: begin // word
                        mem[latch_addr[$clog2(MEM_BYTES)-1:0]]     <= latch_wdata[7:0];
                        mem[latch_addr[$clog2(MEM_BYTES)-1:0]+1]   <= latch_wdata[15:8];
                        mem[latch_addr[$clog2(MEM_BYTES)-1:0]+2]   <= latch_wdata[23:16];
                        mem[latch_addr[$clog2(MEM_BYTES)-1:0]+3]   <= latch_wdata[31:24];
                    end
                endcase
            end else begin
                case (latch_size)
                    2'd0: read_data <= {24'h0, mem[latch_addr[$clog2(MEM_BYTES)-1:0]]};
                    2'd1: read_data <= {16'h0,
                                         mem[latch_addr[$clog2(MEM_BYTES)-1:0]+1],
                                         mem[latch_addr[$clog2(MEM_BYTES)-1:0]]};
                    default: read_data <= {mem[latch_addr[$clog2(MEM_BYTES)-1:0]+3],
                                            mem[latch_addr[$clog2(MEM_BYTES)-1:0]+2],
                                            mem[latch_addr[$clog2(MEM_BYTES)-1:0]+1],
                                            mem[latch_addr[$clog2(MEM_BYTES)-1:0]]};
                endcase
            end
        end
    end

    // --- protocol checker (sim-only, non-fatal) ------------------------
    // Flags a master that drops m_valid before the transaction it started
    // has actually completed -- this is exactly the class of bug that
    // broke the real MMU's multi-cycle writes, so it's worth catching here
    // early against a clean reference model.
    generate
        if (WARN_ON_EARLY_DEASSERT) begin : chk
            always @(posedge mclk) begin
                if (reset && (state == S_WAIT) && !m_valid) begin
                    $display("[%0t] mmu_sim_model: WARNING - m_valid dropped while a transaction was still in flight (addr=%08h, rw=%0d). Real hardware may hang or corrupt this access.",
                              $time, latch_addr, latch_rw);
                end
            end
        end
    endgenerate

    // ---------------------------------------------------------------------
    // Testbench convenience: poke/peek directly into memory, bypassing the
    // m_valid/s_valid protocol entirely. Call these as hierarchical task
    // calls from your testbench, e.g.:
    //
    //   dut.poke_word(32'h0000_0100, 32'hDEAD_BEEF);
    //   $display("%h", dut.peek_word(32'h0000_0100));
    //
    // Little-endian, same as the read/write path above. These are plain
    // blocking writes to the memory array, so they take effect immediately
    // -- no clock edge, no latency, no protocol needed.
    // ---------------------------------------------------------------------
    // NOTE: MEM_BYTES must be a power of two for this masking to be a
    // correct wrap (true of the default 65536 and of the testbench's 4096).
    function [31:0] mmu_idx(input [31:0] a);
        reg [31:0] t;
        begin
            t = a;
            mmu_idx = t[$clog2(MEM_BYTES)-1:0];
        end
    endfunction

    task poke_byte(input [31:0] addr, input [7:0] data);
        begin
            mem[mmu_idx(addr)] = data;
        end
    endtask

    task poke_half(input [31:0] addr, input [15:0] data);
        begin
            mem[mmu_idx(addr)]   = data[7:0];
            mem[mmu_idx(addr+1)] = data[15:8];
        end
    endtask

    task poke_word(input [31:0] addr, input [31:0] data);
        begin
            mem[mmu_idx(addr)]   = data[7:0];
            mem[mmu_idx(addr+1)] = data[15:8];
            mem[mmu_idx(addr+2)] = data[23:16];
            mem[mmu_idx(addr+3)] = data[31:24];
        end
    endtask

    // Fill `count` bytes starting at addr with the repeating byte value[7:0].
    task poke_fill(input [31:0] addr, input [7:0] value, input [31:0] count);
        integer i;
        begin
            for (i = 0; i < count; i = i + 1)
                mem[mmu_idx(addr+i)] = value;
        end
    endtask

    // Reload memory at runtime from a $readmemh-format file (hex, one byte
    // or word per line per the usual $readmemh rules) -- handy for loading
    // a fresh test image between test cases without re-elaborating.
    task load_hex_file(input [8*256-1:0] filename);
        begin
            $readmemh(filename, mem);
        end
    endtask

    function [7:0] peek_byte(input [31:0] addr);
        peek_byte = mem[mmu_idx(addr)];
    endfunction

    function [15:0] peek_half(input [31:0] addr);
        peek_half = {mem[mmu_idx(addr+1)], mem[mmu_idx(addr)]};
    endfunction

    function [31:0] peek_word(input [31:0] addr);
        peek_word = {mem[mmu_idx(addr+3)], mem[mmu_idx(addr+2)],
                     mem[mmu_idx(addr+1)], mem[mmu_idx(addr)]};
    endfunction

endmodule
