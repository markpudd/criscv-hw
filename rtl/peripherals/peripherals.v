// Peripheral Memory map Glue
module peripherals(input clk,
                     input reset,
                     input wire [31:0] address,
                     input wire rw_req,
                     input wire  rw,
                     input wire[31:0] write_data,
                     input wire[1:0] size,
                     output wire [31:0] read_data,
                     output wire prec,
                     output reg [3:0]port,
                     output sout,
                     input sin,

                     output spi_clk,
                     output spi_out,
                     input  spi_sin,
                     output spi_cs);


  wire  uart_busy;

  reg  ss;
  wire  rec_valid;
  reg  [7:0] sdata;
  //reg  [2:0] tdelay;

  reg [31:0] i_read_data;
  wire [7:0] rec_data;
  wire [7:0] spi_rec_data;
  reg i_prec;
  reg i_port;
  reg rr;
    reg spi_req;
  //	uart  uart(clk, sout,reset,ss,sdata,uart_busy);

	
  uart uart( .sclk(clk),
             .dout(sout),
             .reset(reset),
             .send_request(ss),
             .data(sdata),
             .busy(uart_busy),
             .rec_data(rec_data),
             .rec_valid(rec_valid),
             .din(sin),
             .rr(rr));



  spi spi(.sclk(clk),
          .reset(reset),
          .in_data(sdata),
          .out_data(spi_rec_data),

          .send_request(spi_req),
          .busy(spi_busy),

          .din(spi_sin),
          .dout(spi_out),
          .out_clk(spi_clk),
          .cs(spi_cs));


  assign read_data = i_read_data;
  assign prec = i_prec ;


  reg [1:0] pstate=3'h0;
  //	reg [2:0] delay=0;

  always @ (posedge clk)
  begin
    if(~reset)
    begin
      pstate<=3'h0;
      i_read_data <=0;
      i_prec <= 0;
      ss<=0;
	  spi_req<=0;
    end
    else
    case(pstate)
      2'b00:
      begin
        if(ss == 1 && ~uart_busy )
          ss <=0;
          if(spi_req == 1 && ~spi_busy )
          spi_req <=0;
        if(rw_req)
        begin
          if(address == 32'hffffff00)
          begin
            port <= write_data[3:0];
            i_prec <=1;
            pstate <= 2'b01;
          end
          if(address == 32'hffffff01 && ss ==0)
          begin
            sdata <= write_data[7:0];
            ss<=1;
            i_prec <=1;
            pstate <= 2'b01;
          end
          if(address == 32'hffffff02)
          begin
            i_read_data <= {30'h00000000,rec_valid,uart_busy};
            i_prec <=1;
            pstate <= 2'b01;
          end
          if(address == 32'hffffff03 && rr ==0)
          begin
            i_read_data <= {24'h000000,rec_data};

            if(rec_valid)
            begin
              i_prec <=1;
              rr<=1;
            end
            pstate <= 2'b10;
          end

          //SPI
          if(address == 32'hffffff10 && spi_req ==0)
          begin
            sdata <= write_data[7:0];
            spi_req<=1;
            i_prec <=1;
            pstate <= 2'b01;
          end
          if(address == 32'hffffff11)
          begin
            i_read_data <= spi_busy;
            i_prec <=1;
            pstate <= 2'b01;
          end
          if(address == 32'hffffff12 )
          begin
            i_read_data <= {24'h000000,spi_rec_data};
            i_prec <=1;
            pstate <= 2'b01;
          end

        end
        else
        begin
          rr<=0;   //  clear read signal
          i_prec <=0;

        end
      end
      2'b01:
      begin

        //i_prec <=0;
        pstate <= 2'b00;
      end

      2'b10:
      begin
        //i_prec <=0;
        pstate <= 2'b00;
      end
    endcase
  end

endmodule

