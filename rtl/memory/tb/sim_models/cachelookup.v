// Simulation replacement for the Quartus cache tag RAM primitive.
`timescale 1ns/1ps

module cachelookup (
    input  wire [6:0]  address,
    input  wire [1:0]  byteena,
    input  wire        clock,
    input  wire [15:0] data,
    input  wire        wren,
    output reg  [15:0] q
);
    reg [15:0] mem [0:127];
    integer i;

    initial begin
        q = 16'h0000;
        for (i = 0; i < 128; i = i + 1)
            mem[i] = 16'h0000;
    end

    always @(posedge clock) begin
        if (wren)
            mem[address] <= data;
        q <= wren ? data : mem[address];
    end
endmodule