//==========================================================================
// ram.v -- SIMULATION STUB ONLY.
//
// Behavioural stand-in for the Quartus MegaWizard `ram` (altsyncram)
// instance inside mmu.v, so the MMU can be simulated in Icarus Verilog.
// Do NOT add this file to the Quartus project.
//
// Models a single-port, 16-bit wide, byte-enabled M9K with a registered
// (1 cycle latency) output.  Port list matches the instantiation in mmu.v:
//     ram ram(.address(), .byteena(), .clock(), .data(), .wren(), .q());
//
// Word 'n' holds byte address 2n in q[15:8] and byte address 2n+1 in q[7:0]
// -- i.e. big-endian *within* the 16-bit word.  That is what mmu.v's byte
// swizzle assumes; the CPU-facing side is still little-endian.  Anything
// you $readmemh into the real RAM (boot.hex) must use the same ordering.
//==========================================================================
`timescale 1ns/1ps

module ram #(
    parameter ADDR_W  = 14,          // must equal LOW_RAM_WIDTH+1 in mmu.v
    parameter RDW_NEW = 1            // 1 = read-during-write returns new data
) (
    input  wire [ADDR_W-1:0] address,
    input  wire [1:0]        byteena, // [1]=q[15:8], [0]=q[7:0]
    input  wire              clock,
    input  wire [15:0]       data,
    input  wire              wren,
    output reg  [15:0]       q
);

    localparam DEPTH = (1 << ADDR_W);

    reg [15:0] mem [0:DEPTH-1];
    reg [15:0] wval;
    integer    i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1) mem[i] = 16'h0000;
        q = 16'h0000;
    end

    always @(posedge clock) begin
        wval = mem[address];
        if (wren) begin
            if (byteena[0]) wval[7:0]  = data[7:0];
            if (byteena[1]) wval[15:8] = data[15:8];
            mem[address] <= wval;
        end
        q <= (wren && RDW_NEW) ? wval : mem[address];
    end

    //----------------------------------------------------------------------
    // Backdoor access for the testbench (byte addressed, matches mmu.v's
    // ram_address = br_address[ADDR_W:1] mapping).
    //----------------------------------------------------------------------
    task poke_byte(input [31:0] a, input [7:0] d);
        begin
            if (a[0]) mem[a[ADDR_W:1]][7:0]  = d;
            else      mem[a[ADDR_W:1]][15:8] = d;
        end
    endtask

    function [7:0] peek_byte(input [31:0] a);
        begin
            peek_byte = a[0] ? mem[a[ADDR_W:1]][7:0] : mem[a[ADDR_W:1]][15:8];
        end
    endfunction

endmodule
