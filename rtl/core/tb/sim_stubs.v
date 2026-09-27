//=============================================================================
// sim_stubs.v  -  simulation-only stand-ins for missing submodules
//
// alu.v instantiates `divider` / `udivider` (presumably Quartus megafunction
// IP for RV32M) that weren't among the uploaded sources. div_req is tied to
// 1'b0 in execute.v and the RV32M decode path in alu.v is commented out, so
// these are never actually exercised yet - they exist purely so the design
// elaborates under iverilog. Delete this file once the real IP (or its own
// simulation model) is available, or once RV32M support is wired up.
//=============================================================================

module divider(input clock,
               input      [31:0] denom,
               input      [31:0] numer,
               output reg [31:0] quotient,
               output reg [31:0] remain);
  always @(posedge clock)
  begin
    quotient <= (denom != 0) ? ($signed(numer) / $signed(denom)) : 32'hFFFFFFFF;
    remain   <= (denom != 0) ? ($signed(numer) % $signed(denom)) : numer;
  end
endmodule

module udivider(input clock,
                input      [31:0] denom,
                input      [31:0] numer,
                output reg [31:0] quotient,
                output reg [31:0] remain);
  always @(posedge clock)
  begin
    quotient <= (denom != 0) ? (numer / denom) : 32'hFFFFFFFF;
    remain   <= (denom != 0) ? (numer % denom) : numer;
  end
endmodule
