module jtag_tap (
    // Physical JTAG Pins
    input  wire tck,
    input  wire tms,
    input  wire tdi,
    output reg  tdo,
    input  wire trst_n, // Active-low asynchronous reset

    // Internal Interface Outputs
    output reg [15:0] tap_state, // Hot-encoded state output for external decoding
    output wire shift_dr,
    output wire capture_dr,
    output wire update_dr,
    output wire shift_ir,
    output wire capture_ir,
    output wire update_ir
);

    // State Encoding (4-bit encoding for the 16 states)
    localparam STATE_RESET      = 4'h0;
    localparam STATE_IDLE       = 4'h1;
    localparam STATE_SELECT_DR  = 4'h2;
    localparam STATE_CAPTURE_DR = 4'h3;
    localparam STATE_SHIFT_DR   = 4'h4;
    localparam STATE_EXIT1_DR   = 4'h5;
    localparam STATE_PAUSE_DR   = 4'h6;
    localparam STATE_EXIT2_DR   = 4'h7;
    localparam STATE_UPDATE_DR  = 4'h8;
    localparam STATE_SELECT_IR  = 4'h9;
    localparam STATE_CAPTURE_IR = 4'hA;
    localparam STATE_SHIFT_IR   = 4'hB;
    localparam STATE_EXIT1_IR   = 4'hC;
    localparam STATE_PAUSE_IR   = 4'hD;
    localparam STATE_EXIT2_IR   = 4'hE;
    localparam STATE_UPDATE_IR  = 4'hF;

    reg [3:0] current_state;
    reg [3:0] next_state;

    // 1. Next State Combinational Logic (Strictly governed by TMS)
    always @(*) begin
        case (current_state)
            STATE_RESET:      next_state = tms ? STATE_RESET      : STATE_IDLE;
            STATE_IDLE:       next_state = tms ? STATE_SELECT_DR  : STATE_IDLE;
            
            // DR Path
            STATE_SELECT_DR:  next_state = tms ? STATE_SELECT_IR  : STATE_CAPTURE_DR;
            STATE_CAPTURE_DR: next_state = tms ? STATE_EXIT1_DR   : STATE_SHIFT_DR;
            STATE_SHIFT_DR:   next_state = tms ? STATE_EXIT1_DR   : STATE_SHIFT_DR;
            STATE_EXIT1_DR:   next_state = tms ? STATE_UPDATE_DR  : STATE_PAUSE_DR;
            STATE_PAUSE_DR:   next_state = tms ? STATE_EXIT1_DR   : STATE_PAUSE_DR;
            STATE_EXIT2_DR:   next_state = tms ? STATE_UPDATE_DR  : STATE_SHIFT_DR;
            STATE_UPDATE_DR:  next_state = tms ? STATE_SELECT_DR  : STATE_IDLE;
            
            // IR Path
            STATE_SELECT_IR:  next_state = tms ? STATE_RESET      : STATE_CAPTURE_IR;
            STATE_CAPTURE_IR: next_state = tms ? STATE_EXIT1_IR   : STATE_SHIFT_IR;
            STATE_SHIFT_IR:   next_state = tms ? STATE_EXIT1_IR   : STATE_SHIFT_IR;
            STATE_EXIT1_IR:   next_state = tms ? STATE_UPDATE_IR  : STATE_PAUSE_IR;
            STATE_PAUSE_IR:   next_state = tms ? STATE_EXIT1_IR   : STATE_PAUSE_IR;
            STATE_EXIT2_IR:   next_state = tms ? STATE_UPDATE_IR  : STATE_SHIFT_IR;
            STATE_UPDATE_IR:  next_state = tms ? STATE_SELECT_DR  : STATE_IDLE;
            default:          next_state = STATE_RESET;
        endcase
    end

    // 2. State Register (Changes on Rising Edge of TCK)
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            current_state <= STATE_RESET;
        end else begin
            current_state <= next_state;
        end
    end

    // 3. One-hot State Output (Useful for driving external hardware blocks)
    always @(*) begin
        tap_state = 16'b0;
        tap_state[current_state] = 1'b1;
    end

    // Assign helper outputs for readability
    assign capture_dr = tap_state[STATE_CAPTURE_DR];
    assign shift_dr   = tap_state[STATE_SHIFT_DR];
    assign update_dr  = tap_state[STATE_UPDATE_DR];
    assign capture_ir = tap_state[STATE_CAPTURE_IR];
    assign shift_ir   = tap_state[STATE_SHIFT_IR];
    assign update_ir  = tap_state[STATE_UPDATE_IR];

    // 4. TDO Output Logic (IEEE 1149.1 specifies TDO changes on the FALLING edge of TCK)
    // In a real application, you would connect an internal multiplexer here to shift out 
    // either the IR chain or the selected DR chain depending on the active state.
    always @(negedge tck or negedge trst_n) begin
        if (!trst_n) begin
            tdo <= 1'b0;
        end else if (shift_ir) begin
            tdo <= tdi; // Example bypass loopback for IR
        end else if (shift_dr) begin
            tdo <= tdi; // Example bypass loopback for DR
        end else begin
            tdo <= 1'b0;
        end
    end

endmodule
