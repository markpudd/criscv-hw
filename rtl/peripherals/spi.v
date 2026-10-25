
module spi(input wire sclk,
             input reset,

             input wire [7:0] in_data,

             output wire [7:0] out_data,
             input wire send_request,
             output wire busy,
             input wire din,
             output reg dout,
             output reg out_clk,
             output reg cs);


  localparam CLOCK = 50000000;
  localparam SCLK_SPEED = 4000000;
  localparam SPI_TIME_DELAY = CLOCK/SCLK_SPEED/2;  // 2 transition per clock

  localparam CS_IDLE= 1'b1;
  localparam DS_EDGE_SAMPLE = 1'b1;
  localparam DS_EDGE_CHANGE = 1'b0;

  reg [15:0] clock_count;

  reg [7:0] in_byte;
  reg [7:0] out_byte;

  reg [4:0] bit_pos;

  assign out_data = out_byte;
  reg send_request_delayed;
  always @(posedge sclk) send_request_delayed <= send_request;
  wire send_request_edge = (send_request != send_request_delayed); // High for 1 cycle when data changes

  assign busy = ~cs;
  always @(posedge sclk)
  begin
    if(~reset)
    begin
      clock_count <= 0;
      out_clk <= CS_IDLE;
      bit_pos <=8;
      cs <= CS_IDLE;
      out_byte <= 0;
      dout <=0;
    end
    else
    begin
      if(send_request_edge  && send_request)
      begin
        clock_count <= 0;
        out_clk <= CS_IDLE;
        bit_pos <=8;   // 15 clock transitions
        cs <= ~CS_IDLE;
        in_byte <= in_data;  // latch the input for saftey
        out_byte <= 0;
      end
      if(busy)
      begin
        if(clock_count == SPI_TIME_DELAY)
        begin
          clock_count <=0;
          out_clk <= ~out_clk;
        end
      else
        clock_count  <= clock_count+1;


      if(clock_count == SPI_TIME_DELAY/2)
      begin

      end


      if(clock_count == 0)
      begin


        if(out_clk == DS_EDGE_SAMPLE)  // In bit
        begin
          out_byte <= {out_byte[6:0],din };
        end


        if(bit_pos == 0)
        begin
          cs <= CS_IDLE;
         // out_data <= out_byte;
          dout <= 0;
           bit_pos <= bit_pos - 5'd1;
        end
        else
        begin
          if(out_clk == DS_EDGE_CHANGE )
          begin
            dout <= in_byte[bit_pos[3:0]-1];
            bit_pos <= bit_pos -  5'd1;
          end
        end




      end

    end
    end
  end


endmodule
