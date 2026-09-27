`timescale 1ns / 1ps

module peripherals_tb;

  reg clk;
  reg reset;
  reg [31:0] address;
  reg rw_req;
  reg rw;
  reg [31:0] write_data;
  reg [1:0] size;
  wire [31:0] read_data;
  wire prec;
  wire [3:0] port;
  wire sout;
  reg sin;

  peripherals dut (
    .clk(clk),
    .reset(reset),
    .address(address),
    .rw_req(rw_req),
    .rw(rw),
    .write_data(write_data),
    .size(size),
    .read_data(read_data),
    .prec(prec),
    .port(port),
    .sout(sout),
    .sin(sin)
  );

  always #5 clk = ~clk;

  task check;
    input expected_prec;
    input [8*80-1:0] message;
    begin
      if (prec !== expected_prec)
        $fatal(1, "%0s: expected prec=%b, got prec=%b", message, expected_prec, prec);
    end
  endtask

  initial begin
    $dumpfile("peripherals_tb.vcd");
    $dumpvars(0, peripherals_tb);

    clk = 1'b0;
    reset = 1'b0;
    address = 32'h0;
    rw_req = 1'b0;
    rw = 1'b0;
    write_data = 32'h0;
    size = 2'b0;
    sin = 1'b1;

    repeat (2) @(posedge clk);
    #1;
    check(1'b0, "reset clears prec");
    reset = 1'b1;

    address = 32'hffffff01;
    write_data = 32'h0000000a;
    rw_req = 1'b1;
    @(posedge clk);
    #1;
    check(1'b1, "rw_req sets prec");
    //if (port !== 4'ha)
      //$fatal(1, "write transaction did not update port");
    #500
    repeat (3) begin
      @(posedge clk);
      #1;
      check(1'b1, "prec remains set while rw_req is asserted");
    end

    rw_req = 1'b0;
    @(posedge clk);
    #1;
    check(1'b0, "clearing rw_req clears prec");

    $display("peripherals handshake test passed");
    $finish;
  end

endmodule