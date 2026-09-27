//==========================================================================
// ram32.v -- SIMULATION STUB ONLY.
//
// 32-bit behavioral stand-in for a byte-enabled Quartus RAM primitive.
// The output is registered with one clock cycle of latency. Byte address 0
// is stored in q[31:24], byte address 1 in q[23:16], byte address 2 in
// q[15:8], and byte address 3 in q[7:0]. This matches the byte ordering of
// ram.v while widening the data path.
//
// Port list:
//     ram32 ram32(.address(), .byteena(), .clock(), .data(), .wren(), .q());
//
// Do NOT add this file to the Quartus project.
//==========================================================================
`timescale 1ns/1ps

module ram #(
    parameter ADDR_W  = 13,          // word address width; 32 KiB by default
    parameter RDW_NEW = 1            // 1 = read-during-write returns new data
) (
    input  wire [ADDR_W-1:0] address,
    input  wire [3:0]        byteena, // [3]=q[31:24], ..., [0]=q[7:0]
    input  wire               clock,
    input  wire [31:0]       data,
    input  wire               wren,
    output reg  [31:0]       q
);

    localparam DEPTH = (1 << ADDR_W);

    reg [31:0] mem [0:DEPTH-1];
    reg [31:0] wval;
    integer    i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1) mem[i] = 32'h0000_0000;
        q = 32'h0000_0000;
    end

    always @(posedge clock) begin
        wval = mem[address];
        if (wren) begin
            if (byteena[0]) wval[7:0]   = data[7:0];
            if (byteena[1]) wval[15:8]  = data[15:8];
            if (byteena[2]) wval[23:16] = data[23:16];
            if (byteena[3]) wval[31:24] = data[31:24];
            mem[address] <= wval;
        end
        q <= (wren && RDW_NEW) ? wval : mem[address];
    end

    // Byte-addressed backdoor access for testbenches.
    task poke_byte(input [31:0] a, input [7:0] d);
        begin
            case (a[1:0])
                2'b00: mem[a[ADDR_W+1:2]][31:24] = d;
                2'b01: mem[a[ADDR_W+1:2]][23:16] = d;
                2'b10: mem[a[ADDR_W+1:2]][15:8]  = d;
                2'b11: mem[a[ADDR_W+1:2]][7:0]   = d;
            endcase
        end
    endtask

    function [7:0] peek_byte(input [31:0] a);
        begin
            case (a[1:0])
                2'b00: peek_byte = mem[a[ADDR_W+1:2]][31:24];
                2'b01: peek_byte = mem[a[ADDR_W+1:2]][23:16];
                2'b10: peek_byte = mem[a[ADDR_W+1:2]][15:8];
                2'b11: peek_byte = mem[a[ADDR_W+1:2]][7:0];
            endcase
        end
    endfunction

endmodule
