// Simulation replacement for the Quartus cache RAM primitive.
`timescale 1ns/1ps

module cache (
    input  wire [11:0] address,
    input  wire [1:0]  byteena,
    input  wire        clock,
    input  wire [15:0] data,
    input  wire        wren,
    output reg  [15:0] q
);
    reg [15:0] mem [0:4095];
    reg [15:0] next_data;
    integer i;

    initial begin
        q = 16'h0000;
        for (i = 0; i < 4096; i = i + 1)
            mem[i] = 16'h0000;
    end

    always @(posedge clock) begin
        next_data = mem[address];
        if (wren) begin
            if (byteena[0]) next_data[7:0] = data[7:0];
            if (byteena[1]) next_data[15:8] = data[15:8];
            mem[address] <= next_data;
        end
        q <= wren ? next_data : mem[address];
    end
endmodule