module cache_hw (
    input  wire        clock,
    input  wire        burst,        // 1 = SDRAM side owns the port
    // CPU view: 32-bit words
    input  wire [10:0] w_address,
    input  wire [3:0]  w_be,
    input  wire [31:0] w_data,
    input  wire        w_wren,
    output wire [31:0] w_q,
    // SDRAM view: 16-bit halfwords, same timing as a 16-bit RAM
    input  wire [11:0] h_address,
    input  wire [15:0] h_data,
    input  wire        h_wren,
    output wire [15:0] h_q
);
    reg h_sel;
    always @(posedge clock) h_sel <= h_address[0];   // tracks the RAM's address register

	 

    cache ram (
        .clock  (clock),
        .address(burst ? h_address[11:1] : w_address),
        .byteena(burst ? (h_address[0] ? 4'b1100 : 4'b0011) : w_be),
        .data   (burst ? {h_data, h_data} : w_data),
        .wren   (burst ? h_wren : w_wren),
        .q      (w_q));

        assign h_q = h_sel ? w_q[31:16] : w_q[15:0];
endmodule