//=============================================================================
// fetch.v  -  criscv instruction fetch (IF) stage
//
// Extracted verbatim from criscv.v.  Holds the PC, the fetch state machine
// and the instruction-side memory request.  Produces the IF/ID pipeline
// register.
//=============================================================================

module fetch(input             mclk,
               input             reset,
               input             sys_ready,

               // hazard unit (currently unused inside the stage, exactly as in
               // the original - the `if(~stall)` guard is still commented out)
               input             stall,


               input             ifid_flush,

               // redirect from EX
               input             branch_taken,
               input      [31:0] branch_target,

               // memory request (drives the core's external memory port)
               output reg [31:0] addr_i,
               output reg [1:0] size_i,
               input      [31:0] mem_read_data,
               output reg    m_valid,
               input    s_valid,


               // IF/ID pipeline register
               output reg [31:0] IFID_inst,
               output reg [31:0] IFID_pc,


               // Pipeline IFID Handshake
               output reg IFID_valid,
               input ID_ready);

  reg [31:0] pc = 32'h000000c0;

  localparam 	FS_IDLE = 2'd1,
              FS_NORMAL = 2'd0,
              FS_MISS = 2'd2,
              FS_BRANCH = 2'd3;


  (* keep, noprune *)reg [1:0] fetch_state /* synthesis preserve */;

  (* preserve, noprune *) reg trig;


  always @(posedge mclk) trig <= (IFID_pc == 32'h000001dc);

  reg is_current_req_branch_taken;

  // main cycle
  always @ ( posedge mclk)
  begin
    if(sys_ready)
    begin
      // If there is a stall this means we are waiting for memory or ALU in which case we can hold current pipeline as
      // everying is frozen,
      // TODO there is likely an optimzation here were we can add a nop
      //  The third case is we have recieved memory (m_valid and s_valid).  This case we need to increase PC and
      //  set instruction but we need to move m_valid to 0 as mem read triggers on pos edge. Once we've set m_valid
      //  to 0 stall should be removed
      //  TODO Branch
      // if(ID_ready)
      //  begin


      
      if (m_valid )  //  we are waiting for intrruction memory
      begin
        if(s_valid)
        begin  // we have recieved data so latch it
          if(branch_taken && ~is_current_req_branch_taken)  // we have a branch redirect and the current request was a branch
          begin
            IFID_inst  <= 32'h00000013;
            IFID_pc    <= pc;
            fetch_state <= FS_NORMAL;
            IFID_valid <= 1'b1;
          end
          else 
          begin
            IFID_inst  <= mem_read_data;
            IFID_pc    <= pc;
            fetch_state <= FS_NORMAL;
            IFID_valid <= 1'b1;
          end
           m_valid    <= 1'b0;  // Handshake
           
        end
      end
      // end
      else
      begin  
        if(ID_ready) // we are ready to accept a new instruction so request one
        begin     // There is no stall as cache is not enabled we just request
        // is there a branch redirect?  If so we need to set the PC to the branch target and request instruction
        if(branch_taken)
        begin
          pc     <= branch_target;
          addr_i <= branch_target;
          IFID_inst  <= 32'h00000013;  // NOP  - basicly a flush
          IFID_pc    <= branch_target; // not sure if this is correct
          IFID_valid <= 1'b0;
          is_current_req_branch_taken = 1'b1;

        end
        else 
        begin
          pc     <= pc+4;
          addr_i <= pc+4;
          IFID_pc <= pc+4;
          IFID_valid <= 1'b0;
          is_current_req_branch_taken = 1'b0;
        end
        size_i <= 2'h2;
        m_valid  <= 1'b1;
        fetch_state <= FS_MISS;
      end
    end
    end


    if(~reset)  // Reset
    begin
      is_current_req_branch_taken = 1'b0;
      pc <= 32'h00000000;
      m_valid <= 1'b1;
      IFID_inst <= 32'h00000013;
      IFID_pc <= 0;
      addr_i <= pc;
      fetch_state <= FS_IDLE;
      IFID_valid <= 1'b0;
    end
  end

endmodule
