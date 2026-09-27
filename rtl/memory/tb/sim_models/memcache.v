//==========================================================================
// memcache.v -- SIMULATION STUB ONLY.
//
// Behavioural stand-in for the real L1 cache / SDRAM front end, so the MMU
// FSM and handshake can be exercised without dragging in l1cache.v,
// the arbiter and sdramburst.  Do NOT add this file to the Quartus project.
//
// Contract modelled (this is the assumption you should sanity-check against
// the real memcache):
//   * `rw_req` stays asserted for the whole beat.
//   * LATENCY clocks after rw_req goes high, `data_valid` is asserted for
//     exactly one clock, and `read_data` is valid during that same clock.
//   * The internal beat counter then re-arms, so a held `rw_req` produces a
//     beat every LATENCY+1 clocks -- which is how mmu.v walks its multi-beat
//     unaligned accesses.
//   * `reset` is active LOW (matches `if(~reset)` in mmu.v).
//
// `ce` is deliberately NOT used to gate the request.  mmu.v drives
// mem_req = s_valid && address[31]==0 && cState!=DONE, with no `ce` term, so
// local-RAM accesses also poke the cache.  This model counts those as
// `spurious_reqs` instead of hiding them.
//==========================================================================
`timescale 1ns/1ps

module memcache #(
    parameter LATENCY = 4,                  // clocks from request to data_valid
    parameter BASE    = 32'h0001_0000,      // first address this model backs
    parameter WORDS   = 32768               // 16-bit words (=64KB)
) (
    input  wire        clk,
    input  wire        mclk,
    input  wire        ce,
    input  wire        reset,               // active low

    input  wire [31:0] address,
    input  wire [1:0]  be,
    input  wire        rw_req,
    input  wire [15:0] write_data,
    input  wire        rw,                  // 1 = write
    output reg  [15:0] read_data,
    output reg         data_valid,
    output wire        busy,

    output wire [31:0] sd_address,
    output wire        sd_rw_req,
    output wire        sd_rw,
    output wire [15:0] sd_write_data,
    output wire [7:0]  sd_burst_len,
    input  wire [15:0] sd_read_data,
    input  wire        sd_data_bursting
);

    reg [15:0] mem [0:WORDS-1];
    reg [15:0] wval;
    reg [7:0]  cnt;
    integer    i;

    integer spurious_reqs;      // clocks on which rw_req was high while ce == 0
    integer beats_served;

    wire        in_range = (address >= BASE) && (address < (BASE + (WORDS*2)));
    wire [31:0] widx     = (address - BASE) >> 1;

    assign busy          = rw_req && !data_valid;
    assign sd_address    = 32'h0;
    assign sd_rw_req     = 1'b0;
    assign sd_rw         = 1'b0;
    assign sd_write_data = 16'h0;
    assign sd_burst_len  = 8'h0;

    initial begin
        for (i = 0; i < WORDS; i = i + 1) mem[i] = 16'h0000;
        read_data     = 16'h0000;
        data_valid    = 1'b0;
        cnt           = 8'h0;
        spurious_reqs = 0;
        beats_served  = 0;
    end

    always @(posedge clk) begin
        if (~reset) begin
            cnt        <= 8'h0;
            data_valid <= 1'b0;
        end else begin
            if (rw_req) begin
                if (!ce) spurious_reqs = spurious_reqs + 1;

                if (cnt == LATENCY[7:0]) begin
                    cnt          <= 8'h0;
                    data_valid   <= 1'b1;
                    beats_served <= beats_served + 1;

                    wval = in_range ? mem[widx] : 16'hxxxx;
                    if (rw && in_range) begin
                        if (be[0]) wval[7:0]  = write_data[7:0];
                        if (be[1]) wval[15:8] = write_data[15:8];
                        mem[widx] <= wval;
                    end
                    read_data <= wval;
                end else begin
                    data_valid <= 1'b0;
                    cnt        <= cnt + 8'h1;
                end
            end else begin
                data_valid <= 1'b0;
                cnt        <= 8'h0;
            end
        end
    end

    //----------------------------------------------------------------------
    // Backdoor access for the testbench (byte addressed).
    //----------------------------------------------------------------------
    task poke_byte(input [31:0] a, input [7:0] d);
        reg [31:0] wi;
        begin
            wi = (a - BASE) >> 1;
            if (a[0]) mem[wi][7:0]  = d;
            else      mem[wi][15:8] = d;
        end
    endtask

    function [7:0] peek_byte(input [31:0] a);
        reg [31:0] wi;
        begin
            wi        = (a - BASE) >> 1;
            peek_byte = a[0] ? mem[wi][7:0] : mem[wi][15:8];
        end
    endfunction

endmodule
