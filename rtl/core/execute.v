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
                 input      [3:0]  IDEX_funct3,
                 input             IDEX_modbit,
                 input      [31:0] IDEX_imm,
                 input      [11:0] IDEX_csr,
                 input      [5:0]  IDEX_rd,
                 input      [31:0] IDEX_pc,
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
                 output reg        mem_rw_d,

                 // Mem handshakes
                 output reg    m_valid_d,
                 input    s_valid_d,

                 // Pipeline IFEX Handshake
                 input      IDEX_valid,
                 output reg   EX_ready);
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
  wire  alu_comp;

  wire [31:0] mpx_csr;

  // CSR Registers to allow for traps, exception and interupts
  //reg [31:0]  machine_trap_setup_regs [7:0] ;
  // reg [31:0]  machine_trap_handling_regs [5:0] ;

  reg [31:0] mtvec;
  reg [31:0] mepc;



  reg [63:0] mcycle;
  reg [63:0] minstret;




  assign mpx_csr = (csr[11:8] == 4'h3) ?
         //   (csr[7:4] == 4'h0) ?  machine_trap_setup_regs[csr[3:0]] :
         //   (csr[7:4] == 4'h3) ?  machine_trap_handling_regs[csr[3:0]] :
         0 :
         (csr[11:8] == 4'hb) ?
         (csr[7:4] == 4'h0) ?  mcycle[31:0] :
         (csr[7:4] == 4'h2) ?   minstret[31:0] :
         (csr[7:4] == 4'h80) ?    mcycle[63:32] :
         (csr[7:4] == 4'h82) ?  minstret[63:32] :
         0
       : 0;


  alu  alui(.clk(mclk),
            .div_req(alu_req),
            .reset(reset),
            .funct3(IDEX_funct3),
            .modbit(IDEX_modbit),
            .imm(IDEX_imm),
            .opcode(IDEX_opcode),
            .rs1(IDEX_rs1),
            .rs2(IDEX_rs2),
            .rd(rd),
            .comp(alu_comp));
  /*
    always @(*)
    begin
      branch_taken  = 1'b0;              // default every path - avoids inferred latches
      branch_target = 32'b0;       // default fall-through, harmless if not taken
   
      if (IDEX_valid)
      begin
        case (IDEX_opcode)
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
              branch_taken = ($signed(IDEX_rs1) >= $signed(IDEX_rs2)); // BGEmodule execute(input             mclk,
            3'b110:
              branch_taken = (IDEX_rs1 < IDEX_rs2);               // BLTU
            3'b111:
              branch_taken = (IDEX_rs1 >= IDEX_rs2);              // BGEU
          endcase
        end
        7'b1101111:
        begin // JAL - always taken
          branch_taken  = 1'b1;
          branch_target = IDEX_pc + IDEX_imm;
        end
        7'b1100111:
        begin // JALR - always taken, target from register not PC
          branch_taken  = 1'b1;
          branch_target = IDEX_rs1 + IDEX_imm;
        end
        7'b1110011 :  // SYSYTEM
        begin
          case (IDEX_funct3)
            3'b000 :
            begin     // ECALL/EBREAK
              if(IDEX_imm == 0)
              begin
                branch_taken  = 1'b1;
                branch_target = mtvec;// + (11*4);
                mepc = IDEX_pc+4;
              end
              else // (USM)RET
              begin
                branch_taken  = 1'b1;
                branch_target = mepc;
              end
            end
          endcase
        end
      endcase
    end
    end*/


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
    EX_ready =  1'b1;                   // default every path - avoids inferred latches
    branch_taken  = 1'b0;              // default every path - avoids inferred latches
    branch_target = 32'b0;       // default fall-through, harmless if not taken

    // same nesting as the sequential block below, so the two behave
    // identically when mem_rw_req_d is still X out of reset
    if(sys_ready)
      if (IDEX_valid) // & IDEX_valid)
      begin
        casex (IDEX_opcode)
          7'b0010011,7'b0110011 :  // ALU - RV32I - combinational logic
          begin
            rf_we    = 1'b1;
            rf_wdata = rd;
          end
          /*     7'b0110011 :  // ALU - RV32M - muti cycle logic
               begin
                 rf_we    = alu_comp;
                 rf_wdata = rd;
               end*/

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
            endcase
          end
			 7'b1101111:
          begin // JAL - always taken
			   branch_taken  = 1'b1;
            branch_target = IDEX_pc + IDEX_imm;
            rf_we    = (rd_index !=0);
            rf_wdata = IDEX_pc+4;

          end
          7'b1100111:
          begin // JALR - always taken, target from register not PC

            branch_taken  = 1'b1;
            branch_target = IDEX_rs1 + IDEX_imm;
				rf_we    = (rd_index !=0);
            rf_wdata = IDEX_pc+4;
          end
          7'b0110111 :  // LUI
          begin
            rf_we    = (IDEX_rd !=0);
            rf_wdata = IDEX_imm;
          end
          7'b0010111 :  // AUIPC
          begin
            rf_we    = (IDEX_rd !=0);
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
             //     mepc = IDEX_pc+4;
                end
                else // (USM)RET
                begin
                  branch_taken  = 1'b1;
                  branch_target = mepc;
                end

              end
              3'b001 :
              begin  // CSRRW
                if(csr[11:10] !== 4'h3)
                begin
                  rf_we    = (IDEX_rd !=0);
                  if(csr[7:6] == 4'h0)
                  begin
                    rf_wdata = csr[11:0];
                    if(csr[5:0] == MTVEC) 
						  begin
              //        mtvec=  IDEX_rs1;
                  //    machine_trap_setup_regs[csr[5:0]]  <= IDEX_rs1;
						  end
                  end
                  else if(csr[7:6] == 4'h3)
                  begin
                    rf_wdata = csr[11:0];
                    if(csr[5:0] == MEPC)
						  begin
                 //     mepc=  IDEX_rs1;
                   //   machine_trap_handling_regs[csr[5:0]]  <= IDEX_rs1;
						   end
                  end
                end
              end
              3'b010 :
              begin  // CSRRS - TODO Fix
                //  rf_we    = 1'b1;
                // rf_wdata    = mpx_csr | rs1;
              end
              3'b011 :
              begin  // CSRRC - TODO Fix
                //  rf_we    = 1'b1;
                // rf_wdata = mpx_csr & ~rs1;
              end
              3'b101 :
              begin  // CSRRWI
                rf_we    = (rd_index != 0);
                rf_wdata = mpx_csr;
              end
              3'b111 :
              begin  // CSRRCI - TODO Fix
                rf_we    = 1'b1;
                rf_wdata = mpx_csr & ~uimm;
              end
              default :
              begin
                rf_we = 1'b0;
              end
            endcase
          end
          default :
          begin
            rf_we = 1'b0;
          end
        endcase
      end
    begin
      casex (IDEX_opcode)
        7'b0000011 :  // LOAD
        begin
          // stall until memory read completes
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
            EX_ready =  1'b1;
          end
          else
          begin
            EX_ready = 0;
            rf_we = 1'b0;
          end
        end
        7'b0100011 :  // STORE - no register write
        begin
          if(s_valid_d & m_valid_d)
            EX_ready =  1'b1;
          else
            EX_ready = 0;

          rf_we = 1'b0;
        end

      endcase
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
    end
    if(sys_ready)
      if(m_valid_d && s_valid_d)
      begin
        m_valid_d <= 0;
      end
      else
      begin
        if (IDEX_valid )
        begin
          minstret<=minstret+63'b1;
          casex (IDEX_opcode)
            7'b0010011,7'b0110011  :  // ALU - RV32I - combinational logic
            begin
              // regs[IDEX_rd] <= rd;  -> rf_* write port above
            end
            /*     7'b0110011 :  // ALU - RV32M - muti cycle logic
                 begin
                   alu_req <= 1;
                   if (alu_comp)
                   begin
                     // regs[IDEX_rd] <= rd;  -> rf_* write port above
                     alu_req <= 0;
                   end
                 end*/
            7'b0000011 :  // LOAD  - From here on in we are pretty much running instrutions
              //         Would be nice to have seperat module but requires
              //         memory multiplexing complexity
            begin
              if(~m_valid_d)
              begin
                // mem_address_d <= IDEX_rs1+$signed(IDEX_imm); // LB
                mem_address_d <= IDEX_rs1+IDEX_imm; // LB
                mem_size_d <= IDEX_funct3[1:0];
                mem_rw_d <= 0;
                m_valid_d<= 1;
              end

            end
            7'b0100011 :  // STORE
            begin
              if(~m_valid_d)
              begin
                mem_size_d <= IDEX_funct3[1:0];
                // mem_address_d <= IDEX_rs1+$signed(IDEX_imm);
                mem_address_d <= IDEX_rs1+IDEX_imm;
                mem_write_data <= IDEX_rs2;
                mem_rw_d <= 1;
                m_valid_d <= 1;
              end

            end
        7'b1110011 :  // SYSYTEM
          begin
            case (IDEX_funct3)
              3'b000 :
              begin     // ECALL/EBREAK - no register write
                if(IDEX_imm == 0)
                begin
               
                  mepc  <= IDEX_pc+4;
                end
                else // (USM)RET
                begin
                end

              end
              3'b001 :
              begin  // CSRRW
                if(csr[11:10] !== 4'h3)
                begin
                //  rf_we    = (IDEX_rd !=0);
                  if(csr[7:6] == 4'h0)
                  begin
                    //rf_wdata = csr[11:0];
                    if(csr[5:0] == MTVEC) 
						  begin
                      mtvec <=  IDEX_rs1;
                  //    machine_trap_setup_regs[csr[5:0]]  <= IDEX_rs1;
						  end
                  end
                  else if(csr[7:6] == 4'h3)
                  begin
                  //  rf_wdata = csr[11:0];
                    if(csr[5:0] == MEPC)
						  begin
                      mepc <=  IDEX_rs1;
                   //   machine_trap_handling_regs[csr[5:0]]  <= IDEX_rs1;
						   end
                  end
                end
              end
              3'b010 :
              begin  // CSRRS - TODO Fix
                //  rf_we    = 1'b1;
                // rf_wdata    = mpx_csr | rs1;
              end
              3'b011 :
              begin  // CSRRC - TODO Fix
                //  rf_we    = 1'b1;
                // rf_wdata = mpx_csr & ~rs1;
              end
              3'b101 :
              begin  // CSRRWI
            //   rf_we    = (rd_index != 0);
             //   rf_wdata = mpx_csr;
              end
              3'b111 :
              begin  // CSRRCI - TODO Fix
          //      rf_we    = 1'b1;
         //       rf_wdata = mpx_csr & ~uimm;
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

endmodule
