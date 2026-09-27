`timescale 1ns/1ps

// Behavioral replacements for the Quartus RAMs used by memcache.v.
module cache (
    input  wire [10:0] address,
    input  wire [3:0]  byteena,
    input  wire        clock,
    input  wire [31:0] data,
    input  wire        wren,
    output reg  [31:0] q
);
    reg [31:0] mem [0:2047];
    reg [31:0] next_data;
    integer i;

    initial begin
        q = 32'h0;
        for (i = 0; i < 2048; i = i + 1)
            mem[i] = 32'h0;
    end

    always @(posedge clock) begin
        next_data = mem[address];
        if (wren) begin
            if (byteena[0]) next_data[7:0]   = data[7:0];
            if (byteena[1]) next_data[15:8]  = data[15:8];
            if (byteena[2]) next_data[23:16] = data[23:16];
            if (byteena[3]) next_data[31:24] = data[31:24];
            mem[address] <= next_data;
        end
        q <= wren ? next_data : mem[address];
    end
endmodule

module cachelookup (
    input  wire [6:0]  address,
    input  wire [1:0]  byteena,
    input  wire        clock,
    input  wire [31:0] data,
    input  wire        wren,
    output reg  [31:0] q
);
    reg [31:0] mem [0:127];
    integer i;

    initial begin
        q = 32'h0;
        for (i = 0; i < 128; i = i + 1)
            mem[i] = 32'h0;
    end

    always @(posedge clock) begin
        if (wren)
            mem[address] <= data;
        q <= wren ? data : mem[address];
    end
endmodule