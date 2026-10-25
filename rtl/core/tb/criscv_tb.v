`timescale 1ns / 1ps
//=============================================================================
// criscv_tb.v  -  starter testbench for the criscv top-level pipeline
//
// Instantiates criscv, provides a simple 1-cycle-latency byte-addressable
// memory (shared for both instruction and data side, matching how the
// arbiter in criscv.v presents a single mem_address/m_valid/s_valid port),
// preloads a short hand-assembled RV32I program, runs it, and dumps the
// register file.
//
// Program under test (addresses are byte addresses, little-endian words):
//
//   0x00  addi x1, x0, 5        x1 = 5
//   0x04  addi x2, x0, 10       x2 = 10
//   0x08  add  x3, x1, x2       x3 = 15   <- needs rs2 (x2) forwarded from EX
//   0x0C  sub  x4, x3, x1       x4 = 10   <- needs rs1 (x3) forwarded from EX
//   0x10  sw   x3, 128(x0)      mem[0x80] = 15
//   0x14  lw   x5, 128(x0)      x5 = 15   <- pipeline stalls on the memory access
//   0x18  add  x6, x5, x5       x6 = 30   <- load-use hazard (rs1/rs2 = just-loaded x5)
//   0x1C  beq  x6, x6, 8        always taken, target = 0x24
//   0x20  addi x7, x0, 99       must be FLUSHED - x7 should stay 0
//   0x24  addi x8, x0, 42       branch target lands here, x8 = 42
//   0x28  jal  x0, 0            park here (jump to self)
//
// Expected final architectural state once the program parks at 0x28:
//   x1=5  x2=10  x3=15  x4=10  x5=15  x6=30  x7=0  x8=42
//
// To add more instructions/hazards: hand-assemble the word (or use a RV32I
// encoder) and add another load_word() call below, keeping data addresses
// (here just 0x80) clear of wherever your code region ends.
//=============================================================================

module criscv_tb;

  //---------------------------------------------------------------------------
  // Clock / reset
  //---------------------------------------------------------------------------
  reg mclk = 1'b0;
  always #5 mclk = ~mclk;          // 10ns period

  reg reset     = 1'b0;            // active-low: 0 = in reset
  reg cpu_reset = 1'b0;            // not wired to anything live in this RTL yet
  reg sd_init_done = 1'b1;

  //---------------------------------------------------------------------------
  // DUT
  //---------------------------------------------------------------------------
  wire        led, crash;

  wire [31:0] inst_addr;
  wire [31:0] data_addr;
  wire [31:0] data_in;
  wire        data_we;
  wire [1:0]  data_size;
  wire        inst_m_valid;
  wire        data_m_valid;

  wire        inst_resp_valid;
  wire        data_resp_valid;

  wire [31:0] mem_address;
  wire        mem_rw;
  wire [31:0] mem_write_data;
  wire [1:0]  mem_size;
  wire        mem_req_valid;
  wire [31:0] mem_read_data;
  wire        mem_s_valid;
  reg         mem_busy = 1'b0;
  reg         mem_owner_data = 1'b0;
  integer     reg_index;

  criscv dut (
    .mclk           (mclk),
    .reset          (reset),
    .cpu_reset      (cpu_reset),
    .led            (led),
    .crash          (crash),
    .inst_addr      (inst_addr),
    .inst_out       (mem_read_data),
    .inst_m_valid   (inst_m_valid),
    .inst_s_valid   (inst_resp_valid),
    .data_addr      (data_addr),
    .data_in        (data_in),
    .data_we        (data_we),
    .data_out       (mem_read_data),
    .data_size      (data_size),
    .data_m_valid   (data_m_valid),
    .data_s_valid   (data_resp_valid),
    .sd_init_done   (sd_init_done)
  );

  //---------------------------------------------------------------------------
  // Shared behavioural memory model for the split instruction/data ports.
  // The core requests its own addresses; the testbench supplies them and the
  // memory model returns the fetched data on the corresponding response strobe.
  //---------------------------------------------------------------------------
  mmu_sim_model #(
    .MEM_BYTES(65536),
    .RESP_LATENCY(1),
    .MEM_INIT_FILE(""),
    .WARN_ON_EARLY_DEASSERT(0)
  ) mem (
    .mclk        (mclk),
    .reset       (reset),
    .address     (mem_address),
    .rw          (mem_rw),
    .write_data  (mem_write_data),
    .size        (mem_size),
    .read_data   (mem_read_data),
    .m_valid     (mem_req_valid),
    .s_valid     (mem_s_valid)
  );

  always @(posedge mclk) begin
    if (!reset) begin
      mem_busy      <= 1'b0;
      mem_owner_data <= 1'b0;
    end else if (!mem_busy && (inst_m_valid || data_m_valid)) begin
      mem_busy       <= 1'b1;
      mem_owner_data <= data_m_valid;
    end else if (mem_busy && mem_s_valid) begin
      mem_busy <= 1'b0;
    end
  end

  assign mem_req_valid = (inst_m_valid | data_m_valid) & ~mem_s_valid;
  assign mem_address = (mem_busy ? mem_owner_data : data_m_valid) ?
                       data_addr : inst_addr;
  assign mem_rw = (mem_busy ? mem_owner_data : data_m_valid) ? data_we : 1'b0;
  assign mem_write_data = (mem_busy ? mem_owner_data : data_m_valid) ?
                          data_in : 32'h0;
  assign mem_size = (mem_busy ? mem_owner_data : data_m_valid) ?
                    data_size : 2'b10;

  assign inst_resp_valid = mem_busy & ~mem_owner_data & mem_s_valid;
  assign data_resp_valid = mem_busy &  mem_owner_data & mem_s_valid;

  //---------------------------------------------------------------------------
  // Program loader
  //---------------------------------------------------------------------------
  task load_word(input [31:0] addr, input [31:0] word);
    begin
      mem.poke_word(addr, word);
    end
  endtask

  initial
  begin
  /*  load_word('h00, 32'h00500093);   // addi x1, x0, 5
    load_word('h04, 32'h00a00113);   // addi x2, x0, 10
    load_word('h08, 32'h002081b3);   // add  x3, x1, x2
    load_word('h0C, 32'h40118233);   // sub  x4, x3, x1
    load_word('h10, 32'h08302023);   // sw   x3, 128(x0)
    load_word('h14, 32'h08002283);   // lw   x5, 128(x0)
    load_word('h18, 32'h00528333);   // add  x6, x5, x5
    load_word('h1C, 32'h00630463);   // beq  x6, x6, 8      (taken)
    load_word('h20, 32'h06300393);   // addi x7, x0, 99     (should be flushed)
    load_word('h24, 32'h02a00413);   // addi x8, x0, 42     (branch target)
    load_word('h28, 32'h0000006f);   // jal  x0, 0          (park)*/


    // c stlye loop test
  /*  load_word('h00, 32'h40000113);   // addi x2, x0, 0x400          sp
    load_word('h04, 32'hfe010113);   // addi x2, x2, -32
    load_word('h08, 32'h02010413);   // addi x8, x2, 32             s0
    load_word('h0C, 32'h30002023);   // sw   x0, 0x300(x0)          clear LED word
    load_word('h10, 32'hfe042623);   // sw   x0, -20(x8)     af0:  sw zero,-20(s0)
    load_word('h14, 32'h0440006f);   // jal  x0, OUTER_COND  af4:  j b38
    load_word('h18, 32'hfe042423);   // sw   x0, -24(x8)     af8:  sw zero,-24(s0)
    load_word('h1C, 32'h0100006f);   // jal  x0, INNER_COND  afc:  j b0c
    load_word('h20, 32'hfe842783);   // lw   x15, -24(x8)    b00:  lw a5,-24(s0)
    load_word('h24, 32'h00178793);   // addi x15, x15, 1     b04:  addi a5,a5,1
    load_word('h28, 32'hfef42423);   // sw   x15, -24(x8)    b08:  sw a5,-24(s0)
    load_word('h2C, 32'hfe842703);   // lw   x14, -24(x8)    b0c:  lw a4,-24(s0)
    load_word('h30, 32'h000007b7);   // lui  x15, 0x0        b10:  lui a5,0xf      -> 0x0
    load_word('h34, 32'h00478793);   // addi x15, x15, 4     b14:  addi a5,a5,1059 -> 4
    load_word('h38, 32'hfee7d4e3);   // bge  x15, x14, BODY  b18:  bge a5,a4,b00
    load_word('h3C, 32'h30000793);   // addi x15, x0, 0x300  b1c:  li a5,-256
    load_word('h40, 32'hfec42703);   // lw   x14, -20(x8)    b20:  lw a4,-20(s0)
    load_word('h44, 32'h0ff77713);   // andi x14, x14, 255   b24:  andi a4,a4,255
    load_word('h48, 32'h00e78023);   // sb   x14, 0(x15)     b28:  sb a4,0(a5)
    load_word('h4C, 32'hfec42783);   // lw   x15, -20(x8)    b2c:  lw a5,-20(s0)
    load_word('h50, 32'h00178793);   // addi x15, x15, 1     b30:  addi a5,a5,1
    load_word('h54, 32'hfef42623);   // sw   x15, -20(x8)    b34:  sw a5,-20(s0)
    load_word('h58, 32'hfec42703);   // lw   x14, -20(x8)    b38:  lw a4,-20(s0)
    load_word('h5C, 32'h00f00793);   // addi x15, x0, 15     b3c:  li a5,15
    load_word('h60, 32'hfae7dce3);   // bge  x15, x14, INIT  b40:  bge a5,a4,af8
    load_word('h64, 32'h0000006f);   // jal  x0, 0                  park
*/
/*
    load_word('h00, 32'h30000113);   // addi x2, x0, 0x300       # sp
    load_word('h04, 32'hff010113);   // addi x2, x2, -16         # main frame
    load_word('h08, 32'h00012023);   // sw   x0, 0(x2)           # i = 0
    load_word('h0C, 32'h00012223);   // sw   x0, 4(x2)           # sum = 0
    load_word('h10, 32'h00a00493);   // addi x9, x0, 10          # limit
    // COND:
    load_word('h14, 32'h00012283);   // lw   x5, 0(x2)           # reload i each pass
    load_word('h18, 32'h0292d663);   // bge  x5, x9, DONE
    load_word('h1C, 32'h00028533);   // add  x10, x5, x0         # a0 = i
    load_word('h20, 32'h034000ef);   // jal  x1, TWICE
    load_word('h24, 32'h00412303);   // lw   x6, 4(x2)           # reload sum
    load_word('h28, 32'h00a30333);   // add  x6, x6, x10         # sum += twice(i)
    load_word('h2C, 32'h00612223);   // sw   x6, 4(x2)
    load_word('h30, 32'h00012283);   // lw   x5, 0(x2)           # callee may have clobbered x5
    load_word('h34, 32'h00128293);   // addi x5, x5, 1
    load_word('h38, 32'h00512023);   // sw   x5, 0(x2)           # i++
    load_word('h3C, 32'hfd9ff06f);   // jal  x0, COND
    load_word('h40, 32'h00100f13);   // addi x30, x0, 1          # flushed
    // DONE:
    load_word('h44, 32'h00412583);   // lw   x11, 4(x2)          # result
    load_word('h48, 32'h00012603);   // lw   x12, 0(x2)          # final i
    load_word('h4C, 32'h01010113);   // addi x2, x2, 16          # pop frame
    load_word('h50, 32'h0000006f);   // jal  x0, 0               # park
    // TWICE:  (0x54) non-leaf, saves ra
    load_word('h54, 32'hff010113);   // addi x2, x2, -16
    load_word('h58, 32'h00112023);   // sw   x1, 0(x2)           # save ra
    load_word('h5C, 32'h00a12223);   // sw   x10, 4(x2)          # save arg
    load_word('h60, 32'h028000ef);   // jal  x1, INC
    load_word('h64, 32'h00a12423);   // sw   x10, 8(x2)          # stash first result
    load_word('h68, 32'h00412503);   // lw   x10, 4(x2)          # restore arg
    load_word('h6C, 32'h01c000ef);   // jal  x1, INC
    load_word('h70, 32'h00812383);   // lw   x7, 8(x2)
    load_word('h74, 32'h00750533);   // add  x10, x10, x7
    load_word('h78, 32'h00012083);   // lw   x1, 0(x2)           # restore ra
    load_word('h7C, 32'h01010113);   // addi x2, x2, 16
    load_word('h80, 32'h00008067);   // jalr x0, 0(x1)           # return
    load_word('h84, 32'h00100e93);   // addi x29, x0, 1          # flushed
    // INC:  (0x88) leaf, no frame
    load_word('h88, 32'h00150513);   // addi x10, x10, 1
    load_word('h8C, 32'h00008067);   // jalr x0, 0(x1)           # return
    load_word('h90, 32'h00100e13);   // addi x28, x0, 1          # flushed

*/

    load_word('h00, 32'h008000ef);   // jal  x1, A        x1 should be 0x04
    load_word('h04, 32'h00100f13);   // addi x30, x0, 1   flushed
    load_word('h08, 32'h01400293);   // addi x5, x0, 0x14
    load_word('h0C, 32'h00028367);   // jalr x6, 0(x5)    x6 should be 0x10
    load_word('h10, 32'h00100e93);   // addi x29, x0, 1   flushed
    load_word('h14, 32'h0000006f);   // jal  x0, 0        park
/*

       load_word('h00, 32'h06400293);   // addi  x5, x0, 0x64        HANDLER address
    load_word('h04, 32'h30529073);   // csrrw x0, mtvec, x5       write, no read
    load_word('h08, 32'h30502373);   // csrrs x6, mtvec, x0       read back
    load_word('h0C, 32'h00000a13);   // addi  x20, x0, 0          trap counter
    load_word('h10, 32'h00000b13);   // addi  x22, x0, 0
    load_word('h14, 32'h00000b93);   // addi  x23, x0, 0
    load_word('h18, 32'h11100a93);   // addi  x21, x0, 0x111
    load_word('h1C, 32'h00000073);   // ecall                     <-- trap 1
    load_word('h20, 32'h001b0b13);   // addi  x22, x22, 1
    load_word('h24, 32'h00000073);   // ecall                     <-- trap 2
    load_word('h28, 32'h001b8b93);   // addi  x23, x23, 1
    load_word('h2C, 32'h02a00393);   // addi   x7, x0, 42
    load_word('h30, 32'h34039473);   // csrrw  x8, mscratch, x7
    load_word('h34, 32'h340024f3);   // csrrs  x9, mscratch, x0   rs1=x0: no write
    load_word('h38, 32'h00c00513);   // addi   x10, x0, 12
    load_word('h3C, 32'h340525f3);   // csrrs  x11, mscratch, x10
    load_word('h40, 32'h34053673);   // csrrc  x12, mscratch, x10
    load_word('h44, 32'h3403d6f3);   // csrrwi x13, mscratch, 7
    load_word('h48, 32'h34046773);   // csrrsi x14, mscratch, 8
    load_word('h4C, 32'h3400f7f3);   // csrrci x15, mscratch, 1
    load_word('h50, 32'h34006873);   // csrrsi x16, mscratch, 0   uimm=0: no write
    load_word('h54, 32'h340028f3);   // csrrs  x17, mscratch, x0
    load_word('h58, 32'h34102973);   // csrrs x18, mepc, x0
    load_word('h5C, 32'h342029f3);   // csrrs x19, mcause, x0
    load_word('h60, 32'h0000006f);   // jal   x0, 0               park
    // HANDLER (0x64)
    load_word('h64, 32'h34202c73);   // csrrs x24, mcause, x0
    load_word('h68, 32'h34102cf3);   // csrrs x25, mepc, x0
    load_word('h6C, 32'h002a1e13);   // slli  x28, x20, 2
    load_word('h70, 32'h30000e93);   // addi  x29, x0, 0x300
    load_word('h74, 32'h01ce8eb3);   // add   x29, x29, x28
    load_word('h78, 32'h019ea023);   // sw    x25, 0(x29)         log this trap's mepc
    load_word('h7C, 32'h001a0a13);   // addi  x20, x20, 1
    load_word('h80, 32'h004c8d13);   // addi  x26, x25, 4
    load_word('h84, 32'h341d1073);   // csrrw x0, mepc, x26       return past the ecall
    load_word('h88, 32'h30200073);   // mret
    load_word('h8C, 32'h00100d93);   // addi  x27, x0, 1          must be flushed*/
  end

  //---------------------------------------------------------------------------
  // Register dump - call this from anywhere (e.g. after $finish, on a
  // trigger PC, or periodically) to see the architectural register file.
  // Reaches into decode.v's regs[] array directly.
  //---------------------------------------------------------------------------
  task dump_regs;
    integer i;
    begin
      $display("---------------------------------------------------");
      $display(" register dump @ time %0t", $time);
      for (i = 0; i < 32; i = i + 1)
        $display("  x%0d = %0d (0x%08h)", i, dut.u_decode.regs[i], dut.u_decode.regs[i]);
      $display("---------------------------------------------------");
    end
  endtask

  
  //---------------------------------------------------------------------------
  // Stimulus
  //---------------------------------------------------------------------------
  initial
  begin
    $dumpfile("criscv_tb.vcd");
    $dumpvars(0, criscv_tb);
    $display("Starting simulation");
    for (reg_index = 0; reg_index < 32; reg_index = reg_index + 1)
      dut.u_decode.regs[reg_index] = 32'b0;
    reset = 1'b0;
    repeat (4) @(posedge mclk);
    #1
    reset = 1'b1;

    // Give the program plenty of cycles to run through and park in the
    // jal-to-self loop at 0x28 (it's harmless to keep clocking after that).
    repeat (25000) @(posedge mclk);

    dump_regs;
    $display("Finished simulation");
    $finish;
  end

endmodule
