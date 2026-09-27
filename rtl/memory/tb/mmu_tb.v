`timescale 1ns / 1ps

module mmu_tb;


  reg clk;
  reg mclk;
  integer count;

  localparam [1:0] SZ_BYTE = 2'd0,
             SZ_HALF = 2'd1,
             SZ_WORD = 2'd2;

  reg         reset = 1'b0;      // active LOW

  reg  [31:0] address     = 32'h0;
  reg         rw          = 1'b0;
  reg  [31:0] write_data  = 32'h0;
  reg  [1:0]  size        = SZ_WORD;
  reg         m_valid     = 1'b0;   // master request valid

  wire [31:0] read_data;
  wire        s_valid;              // slave completion strobe

  wire        sd_ce;
  wire [31:0] sd_address;
  wire        sd_rw_req;
  wire        sd_rw;
  wire [15:0] sd_write_data;
  wire [7:0]  sd_burst_len;
  reg  [15:0] sd_read_data     = 16'h0;
  reg         sd_data_bursting = 1'b0;

  mmu dut (
        .clk              (clk),
        .mclk             (mclk),
        .reset            (reset),
        .address          (address),
        .rw               (rw),
        .write_data       (write_data),
        .size             (size),
        .read_data        (read_data),
        .m_valid          (m_valid),
        .s_valid          (s_valid),
        .sd_ce            (sd_ce),
        .sd_address       (sd_address),
        .sd_rw_req        (sd_rw_req),
        .sd_rw            (sd_rw),
        .sd_write_data    (sd_write_data),
        .sd_burst_len     (sd_burst_len),
        .sd_read_data     (sd_read_data),
        .sd_data_bursting (sd_data_bursting)
      );


  initial
  begin
    clk = 0;
    forever
      #10 clk = ~clk;
  end

  initial
  begin
    mclk = 0;
    forever
      #10 mclk = ~mclk;
  end

  initial
  begin
    $dumpfile ("mem.vcd");
    $dumpvars(0, mmu_tb); 
    $display("Starting simulation");

    reset = 0;
    repeat (2) @(posedge clk);
    reset = 1;

    @(posedge clk);
    address    = 32'h000000c0;
    m_valid    = 1'b1;
    write_data = 32'h12345678;
    rw         = 1'b1;
    size       = SZ_WORD;


        // Wait up to 100 clk cycles for completion
    begin: write_test
    for (count = 0; count < 100; count = count + 1)
    begin
      @(posedge clk);
      #1;               // allow DUT non-blocking assignments to update

      if (s_valid)
      begin
        //if (read_data !== 32'h12345678) 
       //begin
            $display("RAM byte +0xC0.  %h", dut.ram.peek_byte(32'h000000c0));
            $display("RAM byte +0xC1.  %h", dut.ram.peek_byte(32'h000000c1));
            $display("RAM byte +0xC2.  %h", dut.ram.peek_byte(32'h000000c2));
            $display("RAM byte +0xC3.  %h", dut.ram.peek_byte(32'h000000c3));
     //   end
       // else
         // $display("PASS: w %h", read_data);
            disable write_test;
      end
    end
    end
  
    m_valid = 1'b0;
  //  #1000
  @(posedge clk)
     
    //dut.ram.poke_byte(32'h000000c0, 8'h54355378);
    // Send the read request
    //@(posedge clk);
    address = 32'h000000c0;
    rw      = 1'b0;       // read
    size    = SZ_WORD;
    m_valid = 1'b1;

    @(posedge clk);
  //  m_valid = 1'b0;

    // Wait up to 100 clk cycles for completion
    for (count = 0; count < 100; count = count + 1)
    begin
      @(posedge clk);
      #1;               // allow DUT non-blocking assignments to update

      if (s_valid)
      begin
        #10
        if (read_data !== 32'h12345678)
          $display("FAIL: expected 12345678, got %h", read_data);
        else
          $display("PASS: read %h", read_data);

        $finish;
      end
    end

    $display("FAIL: timeout waiting for s_valid");

    $display("Finished testing");
    $finish;
  end

  //always
  //  #2  clk =  ! clk;

endmodule
