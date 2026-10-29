// iram.sv - parameterized single-port RAM with byte enables.
//
// Quartus Standard/Lite can't reliably infer a parameterized byte-enable RAM
// (the parameterized template is Pro-only), so this is a thin wrapper:
//
//   Quartus synthesis -> direct altsyncram instance, driven by the parameters.
//                        No wizard files. ALTERA_RESERVED_QIS is defined by
//                        Quartus integrated synthesis (the same macro the
//                        wizard-generated files use), so no QSF setup needed.
//   Everything else   -> inferred RTL (Vivado per UG901 byte-write-enable
//                        rules, plus ModelSim/Questa/Icarus simulation).
//
// Timing (both branches): registered address, unregistered q -> data valid
// one clock after the address. Matches the mmu's lm_v / RAM_DELAY=0.
//
// Read-during-write differs between branches (altsyncram NEW_DATA_NO_NBE_READ
// vs inferred read-first). The mmu never uses q on a write cycle, so this
// doesn't matter here - check it before reusing somewhere that does.

module iram #(
    parameter ADDR_W    = 14,                   // address port width
    parameter DEPTH_W   = 12,                   // 2**DEPTH_W words
    parameter NB_COL    = 4,                    // byte-enable lanes
    parameter COL_W     = 8,                    // bits per lane (M9K: 8 or 9 when NB_COL > 1)
    parameter INIT_FILE = "UNUSED",             // Quartus: .mif or Intel HEX, "UNUSED" = none
    parameter MEMH_FILE = "",                   // other tools: $readmemh word file, "" = none
    parameter LPM_HINT  = "ENABLE_RUNTIME_MOD=NO" // e.g. "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=LRAM"
)(
    input  wire                    clock,
    input  wire [ADDR_W-1:0]       address,
    input  wire [NB_COL-1:0]       byteena,
    input  wire [NB_COL*COL_W-1:0] data,
    input  wire                    wren,
    output wire [NB_COL*COL_W-1:0] q
);
    localparam int WIDTH = NB_COL * COL_W;
    localparam int WORDS = 1 << DEPTH_W;

    wire [DEPTH_W-1:0] a = address[DEPTH_W-1:0];

`ifdef ALTERA_RESERVED_QIS
    // altsyncram requires width_byteena_a == width_a / byte_size, and M9K only
    // supports 8- or 9-bit byte sizes. With several lanes, each lane is a byte.
    // With one lane, split the word into 8- or 9-bit bytes and drive them all
    // from the single enable (whole-word write, as the wizard config did).
    // One-lane widths must be a multiple of 8 or 9.
    localparam int BYTE_SIZE = (NB_COL > 1)      ? COL_W :
                               (WIDTH % 8 == 0)  ? 8     : 9;
    localparam int BE_W      = WIDTH / BYTE_SIZE;

    wire [BE_W-1:0] be_a;
    generate
        if (NB_COL > 1) begin : g_be_lanes
            assign be_a = byteena;
        end else begin : g_be_word
            assign be_a = {BE_W{byteena[0]}};
        end
    endgenerate

    altsyncram #(
        .operation_mode                ("SINGLE_PORT"),
        .lpm_type                      ("altsyncram"),
        .intended_device_family        ("Cyclone IV E"),
        .ram_block_type                ("M9K"),
        .width_a                       (WIDTH),
        .widthad_a                     (DEPTH_W),
        .numwords_a                    (WORDS),
        .width_byteena_a               (BE_W),
        .byte_size                     (BYTE_SIZE),
        .outdata_reg_a                 ("UNREGISTERED"),
        .outdata_aclr_a                ("NONE"),
        .clock_enable_input_a          ("BYPASS"),
        .clock_enable_output_a         ("BYPASS"),
        .read_during_write_mode_port_a ("NEW_DATA_NO_NBE_READ"),
        .power_up_uninitialized        ("FALSE"),
        .init_file                     (INIT_FILE),
        .lpm_hint                      (LPM_HINT)
    ) u_altsyncram (
        .clock0         (clock),
        .address_a      (a),
        .byteena_a      (be_a),
        .data_a         (data),
        .wren_a         (wren),
        .q_a            (q),
        // unused ports, tied off as the MegaWizard does for SINGLE_PORT
        .aclr0          (1'b0),
        .aclr1          (1'b0),
        .address_b      (1'b1),
        .addressstall_a (1'b0),
        .addressstall_b (1'b0),
        .byteena_b      (1'b1),
        .clock1         (1'b1),
        .clocken0       (1'b1),
        .clocken1       (1'b1),
        .clocken2       (1'b1),
        .clocken3       (1'b1),
        .data_b         (1'b1),
        .eccstatus      (),
        .q_b            (),
        .rden_a         (1'b1),
        .rden_b         (1'b1),
        .wren_b         (1'b0)
    );

`else
    logic [NB_COL-1:0][COL_W-1:0] ram [0:WORDS-1];
    logic [WIDTH-1:0]             q_r;

    generate
        if (MEMH_FILE != "") begin : g_init
            initial $readmemh(MEMH_FILE, ram);
        end
    endgenerate

    always_ff @(posedge clock) begin
        if (wren)
            for (int i = 0; i < NB_COL; i++)
                if (byteena[i]) ram[a][i] <= data[i*COL_W +: COL_W];
        q_r <= ram[a];
    end

    assign q = q_r;
`endif

endmodule