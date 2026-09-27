`timescale 1ns / 1ps

module uart_4byte_tb;

  localparam integer CLOCK_PERIOD_NS = 20;
  localparam integer UART_BIT_CYCLES = 217;
  localparam integer UART_BIT_NS = CLOCK_PERIOD_NS * UART_BIT_CYCLES;

  reg clk;
  reg reset;
  reg send_request;
  reg [7:0] data;
  reg din;
  reg rr;

  wire dout;
  wire busy;
  wire [7:0] rec_data;
  wire rec_valid;

  uart dut (
    .sclk(clk),
    .dout(dout),
    .reset(reset),
    .send_request(send_request),
    .data(data),
    .busy(busy),
    .rec_data(rec_data),
    .rec_valid(rec_valid),
    .din(din),
    .rr(rr)
  );

  always #(CLOCK_PERIOD_NS / 2) clk = ~clk;

  task send_rx_byte;
    input [7:0] byte_value;
    integer bit_index;
    begin
      @(negedge clk);
      din = 1'b0;
      repeat (UART_BIT_CYCLES) @(negedge clk);
      for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
        din = byte_value[bit_index];
        repeat (UART_BIT_CYCLES) @(negedge clk);
      end
      din = 1'b1;
      repeat (UART_BIT_CYCLES) @(negedge clk);
    end
  endtask

  task read_expected_byte;
    input [7:0] expected_byte;
    begin
      wait (rec_valid);
      if (rec_data !== expected_byte)
        $fatal(1, "Expected 0x%02h, received 0x%02h", expected_byte, rec_data);
      $display("Received 0x%02h", rec_data);
      @(negedge clk);
      rr = 1'b1;
      @(posedge clk);
      @(negedge clk);
      rr = 1'b0;
      #1;
    end
  endtask

  initial begin
    $dumpfile("uart_4byte_tb.vcd");
    $dumpvars(0, uart_4byte_tb);

    clk = 1'b0;
    reset = 1'b0;
    send_request = 1'b0;
    data = 8'h00;
    din = 1'b1;
    rr = 1'b0;

    repeat (4) @(posedge clk);
    reset = 1'b1;
    repeat (UART_BIT_CYCLES) @(posedge clk);

    fork
      begin
        send_rx_byte(8'h12);
        send_rx_byte(8'h34);
        send_rx_byte(8'h56);
        send_rx_byte(8'h78);
      end
      begin
        read_expected_byte(8'h12);
        read_expected_byte(8'h34);
        read_expected_byte(8'h56);
        read_expected_byte(8'h78);
      end
    join

    $display("UART four-byte receive test passed");
    $finish;
  end

  initial begin
    #500000;
    $fatal(1, "Timed out waiting for four received bytes");
  end

endmodule