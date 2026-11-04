module fetch(input             mclk,
             input             reset,
             input             sys_ready,
             input             stall,
             input             ifid_flush,

             input             branch_taken,
             input      [31:0] branch_target,

             output     [31:0] addr_i,        // now combinational
             input      [31:0] mem_read_data,
             output            m_valid,       // now combinational
             input             m_ready,       // NEW: inst_m_ready from arbiter
             input             s_valid,       // inst_s_valid from arbiter

             output reg [31:0] IFID_inst,
             output reg [31:0] IFID_pc,
             output reg        IFID_valid,
             input             ID_ready);

  localparam NOP = 32'h00000013;

  reg [31:0] pc;        // next address to request
  reg [31:0] req_pc;    // address of the request currently in flight
  reg        inflight;  // request accepted, response not yet back
  reg        discard;   // in-flight response is wrong-path

  (* preserve, noprune *) reg trig;
  always @(posedge mclk) trig <= (IFID_pc == 32'h00c00160);

  // Next address is visible on the same cycle the previous response lands,
  // and a taken branch goes straight out without waiting a cycle.
  assign addr_i  = branch_taken ? branch_target : pc;
  assign m_valid = reset & sys_ready & ID_ready;
  wire   accept  = m_valid & m_ready;

  // A response is only a real instruction if it isn't wrong-path
  wire   rsp_ok  = s_valid & ~discard & ~branch_taken;

  always @(posedge mclk)
  begin
    if (~reset)
    begin
      pc         <= 32'h00000000;
      req_pc     <= 32'h00000000;
      inflight   <= 1'b0;
      discard    <= 1'b0;
      IFID_inst  <= NOP;
      IFID_pc    <= 32'h00000000;
      IFID_valid <= 1'b0;
    end
    else if (sys_ready)
    begin
      // ---- request tracking
      if (accept)
      begin
        req_pc <= addr_i;           // branch_target if redirecting, else pc
        pc     <= addr_i + 32'd4;
      end
      else if (branch_taken)
        pc <= branch_target;        // couldn't issue yet; send target when arbiter frees
      else if (rsp_ok && !ID_ready)
          pc <= req_pc;  

      if (accept)       inflight <= 1'b1;
      else if (s_valid) inflight <= 1'b0;

      // Branch while a fetch is in flight and not completing this cycle:
      // its response, when it arrives, is wrong-path.
      if (branch_taken && inflight && !s_valid) discard <= 1'b1;
      else if (s_valid)                         discard <= 1'b0;

      // ---- IF/ID register
      if (branch_taken)
      begin
        IFID_inst  <= NOP;
        IFID_pc    <= branch_target;
        IFID_valid <= 1'b1;
      end
      else if (rsp_ok && ID_ready)
      begin
        IFID_inst  <= mem_read_data;
        IFID_pc    <= req_pc;       // PC of the request that just returned
        IFID_valid <= 1'b1;
      end
      else if (ID_ready)
      begin
        IFID_inst  <= NOP;          // nothing arrived: bubble
        IFID_valid <= 1'b1;
      end
    end
    else
    begin
      IFID_inst  <= NOP;
      IFID_valid <= 1'b0;
    end
  end

endmodule