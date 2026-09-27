//=============================================================================
// criscv.v  -  top level
//
// Structural only: system-ready gating, the hazard unit and the wiring
// between fetch.v / decode.v / execute.v.  All stage logic moved out
// unchanged.
//=============================================================================

module criscv(input  mclk,
                input  reset,
                input  cpu_reset,
                output reg led,
                output reg crash,

                output reg [31:0] mem_address,
                output reg mem_rw,
                output [31:0] mem_write_data,
                output reg [1:0] mem_size,
                input [31:0] mem_read_data,

                output reg   m_valid,
                input        s_valid,

                input sd_init_done);


  localparam  SETS       = 16;
  localparam  LINE_WORDS = 8;

  wire sys_ready = reset ; //& sd_init_done;

  /*
    l1cache #(
      .SETS(SETS),
      .LINE_WORDS(LINE_WORDS)
    ) dut (
      .clk(mclk),
      .reset(reset),
      
      .s_req_addr(s_req_addr),
      .s_req_ready(s_req_ready),
      .s_rsp_data(s_rsp_data),
      .s_rsp_valid(s_rsp_valid),
   
      .m_req_addr(mem_address_i),
      .m_req_valid(mem_rw_req_i),
      .m_rsp_data(mem_read_data),
      .m_rsp_valid(mem_rec)
    );
  */

  // Carried over from the original, currently unused
  reg [31:0] delay;
  reg [31:0] instruction;
  
  reg [31:0] mpx_reg;
  /*
    reg [31:0] s_req_addr;
    reg        s_req_ready;
    wire [31:0] s_rsp_data;
    wire        s_rsp_valid;
  */


  //---------------------------------------------------------------------------
  // Inter-stage nets
  //---------------------------------------------------------------------------

  // IF/ID
  wire [31:0] IFID_inst;
  wire [31:0] IFID_pc;

  // ID/EX
  wire [31:0] IDEX_rs1;
  wire [31:0] IDEX_rs2;
  wire [6:0]  IDEX_opcode;
  wire [3:0]  IDEX_funct3;
  wire        IDEX_modbit;
  wire [31:0] IDEX_imm;
  wire [11:0] IDEX_csr;
  wire [5:0]  IDEX_rd;
  wire [31:0] IDEX_pc;


  // decode-stage signals EX uses directly (unpipelined, as in the original)
  wire [11:0] csr;
  wire [4:0]  uimm;
  wire [5:0]  rd_index;

  // register file: array in ID, write port driven from EX

  wire        rf_we;
  wire [5:0]  rf_waddr;
  wire [31:0] rf_wdata;

  // EX -> IF redirect
  wire        branch_taken;
  wire [31:0] branch_target;

  // instruction-side request copies (for the arbiter below)
  wire [31:0] mem_address_i;
  wire        mem_rw_req_i;

  // data-side request (for the arbiter below)
  wire [31:0] mem_address_d;
  wire [1:0]  mem_size_d;
  wire        mem_rw_d;
  wire        mem_rw_req_d;



  //---------------------------------------------------------------------------
  // Hazard Unit
  //---------------------------------------------------------------------------
  reg ifid_flush;
  reg idex_flush;
  reg stall;

  always @(*)
  begin
    //stall = req_d | (busy & owner_d);
     stall = 0; // m_valid_i | m_valid_d;  // stall if there is a memory request//  & ~s_valid; //(mem_rw_req_d & ~mem_rec_d) | (mem_rw_req_i & ~mem_rec_i);
    // Flush on branch
   // ifid_flush = branch_taken & ~stall;
     idex_flush = branch_taken; //& ~stall;
  end


  //---------------------------------------------------------------------------
  // Mem Arb --  AI generated this arb originally and TBH it sucks.......
  //---------------------------------------------------------------------------
  wire [31:0] addr_i, addr_d;
  wire [1:0]  size_i, size_d;
  wire        m_valid_i,  m_valid_d;
  wire        rw_d;              // I-side is always a read

  reg         busy;              // an access is outstanding
  reg         owner_d;           // 1 = D-side owns the outstanding access

  wire        pick_d = m_valid_d;    // D priority
  wire        s_valid_i = s_valid & busy & ~owner_d;
  wire        s_valid_d = s_valid & busy &  owner_d;

  always @(posedge mclk)
  begin
    if (~reset)
    begin
      busy       <= 1'b0;
      owner_d    <= 1'b0;
      m_valid <= 1'b0;
    end
    else if (busy)
    begin
      if (s_valid)
			//if((~m_valid_i & ~owner_d) | (~m_valid_d & owner_d))  // marginally easier to read
			if(~m_valid_i  || ~m_valid_d )  // marginally easier to read
			begin
			  busy       <= 1'b0;
			  m_valid <= 1'b0;
			end
    end
    else if (m_valid_i | m_valid_d)
    begin
      busy        <= 1'b1;
      owner_d     <= pick_d;
      mem_address <= pick_d ? addr_d : addr_i;
      mem_size    <= pick_d ? size_d : size_i;
      mem_rw      <= pick_d ? rw_d   : 1'b0;
      m_valid  <= 1'b1;
    end
  end


  //---------------------------------------------------------------------------
  // Pipeline stages
  //---------------------------------------------------------------------------

wire ID_ready;
wire IFID_valid;
wire EX_ready;
wire        IDEX_valid;
  //  IF - Instruction Fetch
  fetch u_fetch(.mclk(mclk),
                .reset(reset),
                .sys_ready(sys_ready),

                .stall(stall),

                .ifid_flush(ifid_flush),

                .branch_taken(branch_taken),
                .branch_target(branch_target),

                .addr_i(addr_i),
                .size_i(size_i),
                .mem_read_data(mem_read_data),

                .m_valid(m_valid_i),
                .s_valid(s_valid_i),

                .IFID_inst(IFID_inst),
                .IFID_pc(IFID_pc),
                
                // Pipeline IFID Handshake
                .IFID_valid(IFID_valid),
                .ID_ready(ID_ready));


  //  ID - Instruction Decode
  decode u_decode(.mclk(mclk),
                  .sys_ready(sys_ready),
                  .stall(stall),
                  .idex_flush(idex_flush),




                  .IFID_inst(IFID_inst),
                  .IFID_pc(IFID_pc),

                  .rf_we(rf_we),
                  .rf_waddr(rf_waddr),
                  .rf_wdata(rf_wdata),


                  .csr(csr),
                  .uimm(uimm),
                  .rd_index(rd_index),
                  
                  .IDEX_rs1(IDEX_rs1),
                  .IDEX_rs2(IDEX_rs2),
                  .IDEX_opcode(IDEX_opcode),
                  .IDEX_funct3(IDEX_funct3),
                  .IDEX_modbit(IDEX_modbit),
                  .IDEX_imm(IDEX_imm),
                  .IDEX_csr(IDEX_csr),
                  .IDEX_rd(IDEX_rd),
                  .IDEX_pc(IDEX_pc),


                // Pipeline IFID Handshake
                  .IFID_valid(IFID_valid),
                  .ID_ready(ID_ready),


                // Pipeline IFEX Handshake
                  .IDEX_valid(IDEX_valid),
                  .EX_ready(EX_ready));


  //  EX - Instruction Execute
  execute u_execute(.mclk(mclk),
                    .reset(reset),
                    .sys_ready(sys_ready),
                    .stall(stall),


                    .IDEX_rs1(IDEX_rs1),
                    .IDEX_rs2(IDEX_rs2),
                    .IDEX_opcode(IDEX_opcode),
                    .IDEX_funct3(IDEX_funct3),
                    .IDEX_modbit(IDEX_modbit),
                    .IDEX_imm(IDEX_imm),
                    .IDEX_csr(IDEX_csr),
                    .IDEX_rd(IDEX_rd),
                    .IDEX_pc(IDEX_pc),

                    .csr(csr),
                    .uimm(uimm),
                    .rd_index(rd_index),

                    .rf_we(rf_we),
                    .rf_waddr(rf_waddr),
                    .rf_wdata(rf_wdata),

                    .branch_taken(branch_taken),
                    .branch_target(branch_target),

                    .mem_read_data(mem_read_data),

                    .mem_write_data(mem_write_data),

                    .mem_address_d(addr_d),
                    .mem_size_d(size_d),
                    .mem_rw_d(rw_d),

                    .m_valid_d(m_valid_d),
                    .s_valid_d(s_valid_d),
                    
                    
                  // Pipeline IFEX Handshake
                    .IDEX_valid(IDEX_valid),
                    .EX_ready(EX_ready));
                  



endmodule
