`timescale 1ns / 1ps

module uart_simple_tb;

  localparam integer CLOCK_PERIOD_NS = 20;
  localparam integer TX_BIT_NS = CLOCK_PERIOD_NS * 109;
  localparam integer RX_BIT_NS = CLOCK_PERIOD_NS * 218;

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
      @(negedge dut.recclk);
      din = 1'b0;
      #(RX_BIT_NS);
      for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
        din = byte_value[bit_index];
        #(RX_BIT_NS);
      end
      din = 1'b1;
      #(RX_BIT_NS);
    end
  endtask

  initial begin
    $dumpfile("uart_simple_tb.vcd");
    $dumpvars(0, uart_simple_tb);

    clk = 1'b0;
    reset = 1'b0;
    send_request = 1'b0;
    data = 8'h00;
    din = 1'b1;
    rr = 1'b0;

    #200;
    reset = 1'b1;
    #800;

    fork
      begin
        data = 8'h23;
        send_request = 1'b1;
        #(TX_BIT_NS * 11);
        send_request = 1'b0;
      end
      begin
        send_rx_byte(8'hA6);
      end
    join

    wait (rec_valid);
    $display("received byte: 0x%02h", rec_data);
    #100;
    rr = 1'b1;
    #20;
    rr = 1'b0;
    #(RX_BIT_NS * 2);
    $finish;
  end

endmodule