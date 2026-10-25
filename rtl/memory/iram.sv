module iram #(
    parameter ADDR_W    = 14,
    parameter DEPTH_W   = 12,
    parameter NB_COL    = 4,    // byte-enable lanes (e.g., 4)
    parameter COL_W     = 8,    // bits per lane (e.g., 8)
    parameter INIT_FILE = ""
)(
    input  wire                    clock,
    input  wire [ADDR_W-1:0]       address,
    input  wire [NB_COL-1:0]       byteena,
    input  wire [NB_COL*COL_W-1:0] data,
    input  wire                    wren,
    output reg  [NB_COL*COL_W-1:0] q
);

    (* ramstyle = "M9K, no_rw_check" *)
    reg [NB_COL*COL_W-1:0] mem [0:(1<<DEPTH_W)-1];

    // NOTE: If $readmemh with a parameter string prevents inference, 
    // comment out the initial block below during debugging to test if M9K infers.
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    wire [DEPTH_W-1:0] a = address[DEPTH_W-1:0];

    integer i;
    always @(posedge clock) begin
        if (wren) begin
            for (i = 0; i < NB_COL; i = i + 1) begin
                if (byteena[i]) begin
                    mem[a][i*COL_W +: COL_W] <= data[i*COL_W +: COL_W];
                end
            end
        end
        q <= mem[a];
    end

endmodule