//=============================================================================
// execute.v  -  criscv execute (EX) / write-back stage
//
// Branch resolver, ALU instance, machine-mode CSR file and the data-side
// memory sequencing.
//
// The architectural register file lives in decode.v.  The write decisions
// that used to be `regs[IDEX_rd] <= ...` inside the sequential block below
// are now made in the combinational rf_* block, which drives decode's write
// port.  Same conditions, same casex ordering, same posedge - only the array
// moved.
//=============================================================================

module execute(input             mclk,
                 input             reset,
                 input             sys_ready,
                 input             stall,


                 input      [31:0] IDEX_rs1,
                 input      [31:0] IDEX_rs2,
                 input      [6:0]  IDEX_opcode,
                 input      [2:0]  IDEX_funct3,
                 input             IDEX_modbit,
                 input      [31:0] IDEX_imm,
                 input      [11:0] IDEX_csr,
                 input      [5:0]  IDEX_rd,
                 input      [31:0] IDEX_pc,
                 input             IDEX_is_async,
                 // decode-stage signals used directly by EX (unpipelined,
                 // as in the original)
                 input      [11:0] csr,
                 input      [4:0]  uimm,
                 input      [5:0]  rd_index,

                 // register file write port (array lives in decode.v)
                 output reg        rf_we,
                 output reg [5:0]  rf_waddr,
                 output reg [31:0] rf_wdata,

                 // redirect to IF
                 output reg        branch_taken,
                 output reg [31:0] branch_target,

                 // data-side memory
                 input      [31:0] mem_read_data,
                 output reg [31:0] mem_write_data,
                 output reg [31:0] mem_address_d,
                 output reg [1:0]  mem_size_d,
                 output reg      mem_rw_d,

                 // Mem handshakes
                 output reg    m_valid_d,
                 input    s_valid_d,

                 // Pipeline IFEX Handshake
                 input      IDEX_valid,
                 output wire   EX_ready);
  //  Machine CSR offsets
  localparam MTS_BASE     = 12'h300;
  localparam MSTATUS  	 	= 12'h0;
  localparam MISA      	= 12'h1;
  localparam MEDELEG   	= 12'h2;
  localparam MIDELEG   	= 12'h3;
  localparam MIE   			= 12'h4;
  localparam MTVEC   		= 12'h5;
  localparam MCOUNTEREN   = 12'h6;

  localparam MTH_BASE     = 12'h340;
  localparam MSCRATCH  	= 12'h0;
  localparam MEPC      	= 12'h1;
  localparam MCAUSE   		= 12'h2;
  localparam MTVAL   		= 12'h3;
  localparam MIP   			= 12'h4;

  reg  alu_req = 1'b0;

  wire  [31:0] rd;


  reg [31:0] mpx_csr;

  // CSR Registers to allow for traps, exception and interupts
  //reg [31:0]  machine_trap_setup_regs [7:0] ;
  // reg [31:0]  machine_trap_handling_regs [5:0] ;

  reg [31:0] mtvec;
  reg [31:0] mepc;


  reg  [5:0]  IDEX_rd_as;

  reg [63:0] mcycle;
  reg [63:0] minstret;

  // reg [31:0] mtval;


  reg s_ready;


  // in EX, combinational — same instruction, same cycle
  /* wire [31:0] ls_addr = IDEX_rs1 + IDEX_imm;   // your existing address adder
   wire        misaligned_mem = m_valid_d && (
                 (IDEX_funct3[1:0] == 2'b01 && ls_addr[0])         ||
                 (IDEX_funct3[1:0] == 2'b10 && ls_addr[1:0] != 2'b00)
               );*/

  wire        is_load  = (IDEX_opcode == 7'b0000011);
  wire        is_store = (IDEX_opcode == 7'b0100011);
  wire [31:0] ls_addr  = IDEX_rs1 + IDEX_imm;
  wire misaligned_mem  = IDEX_valid && (is_load || is_store) && (
         (IDEX_funct3[1:0] == 2'b01 && ls_addr[0])           ||   // LH/LHU/SH
         (IDEX_funct3[1:0] == 2'b10 && ls_addr[1:0] != 2'b00));

  // wire misaligned_mem  = m_valid_d && (
  //       (mem_size_d == 2'b01 && mem_address_d[0])          ||   // halfword on odd address
  //    (mem_size_d == 2'b10 && mem_address_d[1:0] != 2'b00)    // word not 4-aligned
  //   );


  reg [31:0] mstatus, mscratch, mcause, mtval;   // mtvec, mepc already declared

  always @*
  begin
    case (IDEX_csr)
      12'h300:
        mpx_csr = mstatus;
      12'h301:
        mpx_csr = 32'h40000100;     // misa: MXL=1 (RV32), I
      12'h305:
        mpx_csr = mtvec;
      12'h340:
        mpx_csr = mscratch;
      12'h341:
        mpx_csr = mepc;
      12'h342:
        mpx_csr = mcause;
      12'h343:
        mpx_csr = mtval;
      12'hB00, 12'hC00:
        mpx_csr = mcycle[31:0];
      12'hB80, 12'hC80:
        mpx_csr = mcycle[63:32];
      12'hB02, 12'hC02:
        mpx_csr = minstret[31:0];
      12'hB82, 12'hC82:
        mpx_csr = minstret[63:32];
      default:
        mpx_csr = 32'b0;   // incl. mhartid (0xF14)
    endcase
  end

  // CSR write value: RW / RS / RC, register or immediate form
  wire [31:0] csr_src = IDEX_funct3[2] ? IDEX_imm : IDEX_rs1;
  reg  [31:0] csr_wdata;
  always @*
  begin
    case (IDEX_funct3[1:0])
      2'b01:
        csr_wdata = csr_src;              // CSRRW(I)
      2'b10:
        csr_wdata = mpx_csr |  csr_src;   // CSRRS(I) - csrr is rs1=x0, writes same value back
      2'b11:
        csr_wdata = mpx_csr & ~csr_src;   // CSRRC(I)
      default:
        csr_wdata = mpx_csr;
    endcase
  end


  wire  alu_busy;

  alu  alui(.clk(mclk),
            .div_req(alu_issue | alu_req),
            .reset(reset),
            .funct3(IDEX_funct3),
            .modbit(IDEX_modbit),
            .imm(IDEX_imm),
            .opcode(IDEX_opcode),
            .rs1(IDEX_rs1),
            .rs2(IDEX_rs2),
            .rd(rd),
            .busy(alu_busy));


  wire alu_busy_op = (alu_issue | alu_req) & ~alu_done;
  assign EX_ready = s_ready ; //& ~alu_busy_op;
  wire alu_issue = sys_ready & IDEX_valid & IDEX_is_async & ~alu_req ; //& ~alu_complete;
  wire alu_done  = alu_req & ~alu_busy;

  //---------------------------------------------------------------------------
  // Register file write port.
  //
  // Combinational mirror of the register writes in the sequential block
  // below: the enable carries the same guards the always block sits under
  // (sys_ready, no data access in flight, not stalled) and the casex arms
  // are in the same order with the same per-opcode conditions.  Keep the two
  // blocks in step when adding instructions.
  //---------------------------------------------------------------------------
  always @(*)
  begin
    rf_we    = 1'b0;                   // default every path - avoids inferred lamem_size_dtches
    rf_waddr = IDEX_rd;
    rf_wdata = rd;
    s_ready =  1'b1;                   // default every path - avoids inferred latches
    branch_taken  = 1'b0;              // default every path - avoids inferred latches
    branch_target = 32'b0;       // default fall-through, harmless if not taken
    // mem_rw_d = 0;
    // same nesting as the sequential block below, so the two behave
    // identically when mem_rw_req_d is still X out of reset
    if(sys_ready)
    begin

      if (alu_done)
      begin
        rf_we    = 1'b1;
        rf_waddr = IDEX_rd_as;
        rf_wdata = rd;
        s_ready = 1'b1;
      end
      else if (alu_req)
        s_ready = 1'b0;
      else if (IDEX_valid && !alu_req) // & IDEX_valid)
      begin
        casex (IDEX_opcode)
          7'b0010011,7'b0110011 :  // ALU
          begin
            //  RV32I - combinational logic
            rf_we    = ~IDEX_is_async;
            rf_wdata = rd;
          end
          7'b1100011:
          begin // BRANCH
            branch_target = IDEX_pc + IDEX_imm;
            case (IDEX_funct3)
              3'b000:
                branch_taken = (IDEX_rs1 == IDEX_rs2);              // BEQ
              3'b001:
                branch_taken = (IDEX_rs1 != IDEX_rs2);              // BNE
              3'b100:
                branch_taken = ($signed(IDEX_rs1) < $signed(IDEX_rs2)); // BLT
              3'b101:
                branch_taken = ($signed(IDEX_rs1) >= $signed(IDEX_rs2)); // BGE
              3'b110:
                branch_taken = (IDEX_rs1 < IDEX_rs2);               // BLTU
              3'b111:
                branch_taken = (IDEX_rs1 >= IDEX_rs2);              // BGEU
              default:
                branch_taken =0;
            endcase
          end
          7'b1101111:
          begin // JAL - always taken
            branch_taken  = 1'b1;
            branch_target = IDEX_pc + IDEX_imm;
            rf_we    = 1; //(rd_index !=0);
            rf_wdata = IDEX_pc+4;

          end
          7'b1100111:
          begin // JALR - always taken, target from register not PC

            branch_taken  = 1'b1;
            branch_target = IDEX_rs1 + IDEX_imm;
            rf_we    = 1; //(rd_index !=0);
            rf_wdata = IDEX_pc+4;
          end
          7'b0110111 :  // LUI
          begin
            rf_we    = 1'b1; // (IDEX_rd !=0);
            rf_wdata = IDEX_imm;
          end
          7'b0010111 :  // AUIPC
          begin
            rf_we    = 1'b1;  //(IDEX_rd !=0);
            rf_wdata = IDEX_pc+ IDEX_imm;
          end
          7'b0001111 :  // FENCE
          begin
            rf_we = 1'b0;
          end
          7'b1110011 :  // SYSYTEM
          begin
            case (IDEX_funct3)
              3'b000 :
              begin     // ECALL/EBREAK - no register write
                if(IDEX_imm == 0)
                begin
                  branch_taken  = 1'b1;
                  branch_target = mtvec;// + (11*4);
               //   mcause = 11;
                end
                else // (USM)RET
                begin
                  branch_taken  = 1'b1;
                  branch_target = mepc;
              //    mcause = 11;
                end
              end
              3'b001, 3'b010, 3'b011, 3'b101,3'b110,3'b111  :
              begin
                rf_we    = 1'b1;
                rf_wdata    = mpx_csr;// | IDEX_rs1;
              end
              default :
              begin
              end
            endcase
          end
          default :
          begin
          end
        endcase
      end
      begin
        casex (IDEX_opcode)
          7'b0000011 :  // LOAD
          begin
            if(!misaligned_mem)
            begin
              if(s_valid_d & m_valid_d)
              begin
                rf_we = 1'b1;
                case (IDEX_funct3)
                  3'b000:
                    rf_wdata = {{24{mem_read_data[7]}},  mem_read_data[7:0]};   // LB
                  3'b001:
                    rf_wdata = {{16{mem_read_data[15]}}, mem_read_data[15:0]};  // LH
                  3'b100:
                    rf_wdata = {24'h0, mem_read_data[7:0]};                    // LBU
                  3'b101:
                    rf_wdata = {16'h0, mem_read_data[15:0]};                   // LHU
                  default:
                    rf_wdata = mem_read_data;                                 // LW
                endcase
                s_ready =  1'b1;
              end
              else
              begin
                s_ready = 0;
                rf_we = 1'b0;
              end
            end
            else
            begin
              branch_taken  = 1'b1;
              branch_target = mtvec;// + (11*4);
          //    mcause = 4;
            end

          end
          7'b0100011 :  // STORE - no register write
          begin
            if(!misaligned_mem)
            begin
              if(s_valid_d & m_valid_d)
                s_ready =  1'b1;
              else
                s_ready = 0;

              rf_we = 1'b0;
            end
            else
            begin
              branch_taken  = 1'b1;
              branch_target = mtvec;// + (11*4);
          //    mcause = 6;
            end
          end
          default :
          begin
          end

        endcase
      end
    end
  end


  always @ ( posedge mclk)
    //  always @(*)
  begin
    if(~reset)
    begin
      m_valid_d <= 1'b0;
      mem_rw_d <= 0;
      mepc <= 0;
      mtvec <= 0;
      mcycle<=0;
      minstret<=0;
      alu_req <= 0;
    end
    if(sys_ready)
    begin
      mcycle<=mcycle+63'b1;
      if(m_valid_d && s_valid_d)
      begin
        m_valid_d <= 0;

      end
      else
      begin
        if (IDEX_valid )
        begin
          minstret<=minstret+63'b1;
          if (alu_done)
          begin
            alu_req <= 0;
          end
          else
          casex (IDEX_opcode)
            7'b0010011,7'b0110011  :  // ALU - RV32I - combinational logic
            begin
              if(IDEX_is_async)
              begin
                alu_req <= 1;
                IDEX_rd_as <= IDEX_rd;
              end
            end
            7'b0000011 :  // LOAD  - From here on in we are pretty much running instrutions
              //         Would be nice to have seperat module but requires
              //         memory multiplexing complexity
            begin
              // check - misaligned if so then trap!
              if(~m_valid_d)
              begin
                if(misaligned_mem)
                begin
                  mepc  <= IDEX_pc+4;
                   mcause <= 6'd4 ;
                end
                else
                begin
                  mem_address_d <= IDEX_rs1+IDEX_imm; // LB
                  mem_size_d <= IDEX_funct3[1:0];
                  mem_rw_d <= 0;
                  m_valid_d<= 1;
                end
              end
            end
            7'b0100011 :  // STORE
            begin
              if(~m_valid_d)
              begin
                if(misaligned_mem)
                begin
                  mepc  <= IDEX_pc+4;
                 mcause <= 6'd6;
                end
                else
                begin
                  mem_size_d <= IDEX_funct3[1:0];
                  // mem_address_d <= IDEX_rs1+$signed(IDEX_imm);
                  mem_address_d <= IDEX_rs1+IDEX_imm;
                  mem_write_data <= IDEX_rs2;
                  mem_rw_d <= 1;
                  m_valid_d <= 1;
                end
              end
              if(s_valid_d & m_valid_d)
                mem_rw_d <= 0;
            end
            7'b1110011 :  // SYSYTEM
            begin
              case (IDEX_funct3)
                3'b000 :
                begin     // ECALL/EBREAK - no register write
                  if(IDEX_imm == 0)
                  begin

                    mepc  <= IDEX_pc+4;
                    mcause <= 11;
                  end
                  else // (USM)RET
                  begin
                  end

                end
                3'b001 :
                begin  // CSRRW
                  if(IDEX_csr[11:10] !== 4'h3)
                  begin
                    //  rf_we    = (IDEX_rd !=0);
                    if(IDEX_csr[7:6] == 4'h0)
                    begin
                      //rf_wdata = csr[11:0];
                      if(IDEX_csr[5:0] == MTVEC)
                      begin
                        mtvec <=  IDEX_rs1;
                      end
                    end
                    else if(IDEX_csr[7:6] == 4'h3)
                    begin
                      //  rf_wdata = csr[11:0];
                      if(IDEX_csr[5:0] == MEPC)
                      begin
                        mepc <=  IDEX_rs1;
                      end
                    end
                  end
                end
                3'b001, 3'b010, 3'b011, 3'b101, 3'b110, 3'b111 :
                begin
                  case (IDEX_csr)                        // full 12-bit compare
                    12'h300: mstatus  <= csr_wdata;
                    12'h305: mtvec    <= csr_wdata;
                    12'h340: mscratch <= csr_wdata;
                    12'h341: mepc     <= csr_wdata;
                    12'h342: mcause   <= csr_wdata;
                    12'h343: mtval    <= csr_wdata;
                    default: ;                           // counters/misa read-only
                  endcase
                end
                default :
                begin
                  //       rf_we = 1'b0;
                end
              endcase
            end

          endcase
        end
      end
    end
  end

endmodule
