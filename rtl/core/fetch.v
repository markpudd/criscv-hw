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
               input      [31:0] mem_read_data,
               output reg    m_valid,
               input    s_valid,


               // IF/ID pipeline register
               output reg [31:0] IFID_inst,
               output reg [31:0] IFID_pc,


               // Pipeline IFID Handshake
               output reg IFID_valid,
               input ID_ready);

  reg [31:0] pc;

  localparam 	FS_IDLE = 2'd1,
              FS_NORMAL = 2'd0,
              FS_MISS = 2'd2,
              FS_BRANCH = 2'd3;



    (* preserve, noprune *) reg trig;
    always @(posedge mclk) trig <= (IFID_pc == 32'h00c00160);

reg has_branch;

  // main cycle
  always @ ( posedge mclk)
  begin
    if(~reset)  // Reset
    begin
      pc <= 32'h00000000;
      m_valid <= 1'b1;  // this is actually always requesting
      IFID_inst <= 32'h00000013;
      IFID_pc <= 0;
      addr_i <= pc;
      IFID_valid <= 1'b0;
      has_branch <=0;
    end
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
 // we have recieved data so latch it
        if(~m_valid && ID_ready)
          m_valid<=1;
        if(branch_taken) // we have a branch redirect and the current request was a branch
        begin
          IFID_inst  <= 32'h00000013;
          pc     <= branch_target;
          addr_i <= branch_target;
          IFID_pc    <= branch_target;
          IFID_valid <= 1'b1;   // IFID_inst is nop so can bubble through
          has_branch <= 1;
       //   m_valid<=1;
        end
        else if(s_valid )
        begin
          if(has_branch) // we have a branch redirect and the current request was a branch
          begin
            IFID_inst  <= 32'h00000013;
           // pc     <= branch_target;
            //addr_i <= branch_target;
           // IFID_pc    <= branch_target;
            IFID_valid <= 1'b1;   // IFID_inst is nop so can bubble through
            has_branch <= 0;
          end
          else // if (ID_ready)
          begin 
            IFID_inst  <= mem_read_data;
            pc     <= pc+4;
            addr_i <= pc+4;
            IFID_pc <= pc;
            IFID_valid <= 1'b1;
            if(~ID_ready)
              m_valid <= 1'b0;

          end
        end 
        else if(~s_valid && ID_ready) // we have a valid request but no data yet
        begin
          IFID_inst  <= 32'h00000013;
          IFID_valid <= 1'b1;
        end     
      end
      else
      begin // we don't have vald data so maybe bubble but non valid?
        // Don't update pc though
        IFID_inst  <= 32'h00000013;
        IFID_valid <= 1'b0;
      end
    end
  




endmodule
