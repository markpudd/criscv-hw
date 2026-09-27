//=============================================================================
// decode.v  -  criscv instruction decode (ID) stage
//
// Combinational field/immediate decode of IFID_inst, the architectural
// register file, and the ID/EX pipeline register.
//
// The register file lives here so rs1/rs2 are read in ID and latched into
// IDEX_rs1/IDEX_rs2 before EX sees them.  EX drives the write port
// (rf_we/rf_waddr/rf_wdata) back into this stage; that port is combinational
// on the EX side, so the write still lands on the same posedge it did when
// the array sat inside the EX always block.
//
// csr / uimm / rd_index / rs1_data are exported unpipelined because EX
// consumes the decode-stage copies of them directly, exactly as the original
// did.
//=============================================================================

module decode(input             mclk,
              input             sys_ready,
              input             stall,
              input             idex_flush,


              input      [31:0] IFID_inst,
              input      [31:0] IFID_pc,

              // register file write port, driven from EX
              input             rf_we,
              input      [5:0]  rf_waddr,
              input      [31:0] rf_wdata,

              // decode-stage signals consumed directly by EX (unpipelined)
              output     [11:0] csr,
              output     [4:0]  uimm,
              output     [5:0]  rd_index,

              // ID/EX pipeline register
              output reg [31:0] IDEX_rs1,
              output reg [31:0] IDEX_rs2,
              output reg [6:0]  IDEX_opcode,
              output reg [3:0]  IDEX_funct3,
              output reg        IDEX_modbit,
              output reg [31:0] IDEX_imm,
              output reg [11:0] IDEX_csr,
              output reg [5:0]  IDEX_rd,
              output reg [31:0] IDEX_pc,

              
                // Pipeline IFID Handshake
              input IFID_valid,
              output      ID_ready,



            // Pipeline IFEX Handshake
              output reg        IDEX_valid,
              input EX_ready);

				  
				    wire [31:0] imm_s;
  wire [31:0] imm_u;
  wire [31:0] imm_i;
  wire [31:0] imm_b;
  wire [31:0] imm_j;
  wire        modbit;
  wire [6:0]  opcode;
  wire [31:0] rs1;
  wire [31:0] rs2;
	wire [2:0] funct3;
	
	
  reg [31:0]  regs [31:0] ;

  // write back from EX
  always @ ( posedge mclk)
  begin
    if (rf_we && rf_waddr !=0 )
      regs[rf_waddr] <= rf_wdata;
	//   rs1 = regs[IFID_inst[19:15]];
  // rs2 = regs[IFID_inst[24:20]];
  end

  // ID - Instrruction Decode
  assign imm_i =  $signed(IFID_inst[31:20]);
  assign imm_s =  $signed({IFID_inst[31:25], IFID_inst[11:7]});
  assign imm_b = $signed({IFID_inst[31] ,IFID_inst[7],IFID_inst[30:25],IFID_inst[11:8], 1'b0});
  assign imm_j = $signed({IFID_inst[31],  IFID_inst[19:12], IFID_inst[20], IFID_inst[30:21] ,1'b0 });
  assign imm_u = IFID_inst & 32'hFFFFF000;
    assign opcode = IFID_inst[6:0];
  assign rd_index = IFID_inst[11:7];
  assign funct3 = IFID_inst[14:12];
  assign modbit =IFID_inst[30];
  assign uimm = IFID_inst[19:15];
  assign csr = IFID_inst[31:20];
  assign rs1 = regs[IFID_inst[19:15]];
  assign rs2 = regs[IFID_inst[24:20]];


  // EX -> ID forwarding.
  //
  // The instruction in EX writes its result at the end of the same cycle this
  // instruction spends in ID, so the array read above misses it by one edge.
  // rf_wdata is that result, already valid combinationally, so bypass it
  // straight into the ID/EX latch.  x0 never forwards - reads of x0 must stay
  // zero.  rf_waddr is compared at its full 6 bits, so an out-of-range write
  // (rd >= 32, which the array silently drops) does not produce a false hit.
  wire fwd_rs1 = rf_we & (IFID_inst[19:15] != 0) & (rf_waddr == IFID_inst[19:15]);
  wire fwd_rs2 = rf_we & (IFID_inst[24:20] != 0) & (rf_waddr == IFID_inst[24:20]);

  wire [31:0] rs1_fwd =  (IFID_inst[19:15] == 5'd0) ? 32'd0 : fwd_rs1 ? rf_wdata : rs1;
  wire [31:0] rs2_fwd = (IFID_inst[24:20] == 5'd0) ? 32'd0 :  fwd_rs2 ? rf_wdata : rs2;


  reg [31:0] imm_mux;


 // assign ID_ready = EX_ready;

  always @(*)
  begin
    case (opcode)
      7'b0010011, 7'b0000011, 7'b1100111:
        imm_mux = imm_i; // I-type: ALU-imm, loads, JALR
      7'b0100011:
        imm_mux = imm_s; // S-type: stores
      7'b1100011:
        imm_mux = imm_b; // B-type: branches
      7'b0110111, 7'b0010111:
        imm_mux = imm_u; // U-type: LUI, AUIPC
      7'b1101111:
        imm_mux = imm_j; // J-type: JAL
      default:
        imm_mux = imm_i; // don't-care/default
    endcase
  end

assign ID_ready = EX_ready;
//always @(posedge mclk) begin
//  $display("%0t EX_ready=%b IFID_valid=%b sys_ready=%b", $time, EX_ready, IFID_valid, sys_ready);
//  $strobe ("%0t   -> IDEX_valid after edge = %b", $time, IDEX_valid);
//end

  always @ ( posedge mclk)
  begin
  if(~sys_ready)
  begin
        IDEX_opcode <= 7'b0010011;  // ADDI - decodes as a genuine no-op in EX
        IDEX_rd     <= 6'd0;        // x0 destination - architecturally discarded
        IDEX_funct3 <= 3'b000;
        IDEX_imm    <= 32'd0;
		    IDEX_valid  <= 1'b1;

  end
    if (sys_ready)
    begin
         if ((EX_ready && IFID_valid) || idex_flush)  // normal case: latch new instruction
      begin
		if(~idex_flush)
        IDEX_rs1 <= rs1_fwd;
        IDEX_rs2 <= rs2_fwd;
        IDEX_opcode <= opcode;
        IDEX_funct3 <= funct3;
        IDEX_modbit <= modbit;
        IDEX_imm <= imm_mux;
        IDEX_csr <= csr;
        IDEX_rd  <= rd_index;
		  if(~idex_flush)
        IDEX_pc   <= IFID_pc;
		    IDEX_valid  <= 1'b1;
      end
      else if (EX_ready && ~IFID_valid)
      begin
      IDEX_opcode <= 7'b0010011;  // ADDI - decodes as a genuine no-op in EX
		  //IDEX_opcode <= 7'b0;
		  IDEX_rd     <= 5'b0;
		  IDEX_funct3 <= 3'b0;
		  IDEX_imm    <= 32'b0;
		  IDEX_rs1    <= 32'b0;
		  IDEX_rs2    <= 32'b0;
		  IDEX_pc     <= 32'b0;
		  IDEX_csr    <= 12'b0;
		  IDEX_modbit <= 1'b0;
		  IDEX_valid  <= 1'b1;
      //ID_ready  <= 1'b1;
      end
     


   end
  end

endmodule