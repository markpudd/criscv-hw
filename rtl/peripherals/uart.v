
module uart(input wire sclk,
              output dout,
              input reset,
              input wire send_request,
              input wire [7:0] data,
              output wire busy,
              output wire [7:0] rec_data,
              output wire rec_valid,
              input wire din,
              input wire rr);

  // 50Mhz  clock

  localparam CLOCK = 50000000;
  localparam BAUD = 460800;
  localparam [17:0]  UART_TIME_DELAY = CLOCK/BAUD;
 // localparam UART_TIME_RDELAY =  18'ha2c/18'd12;
 // localparam UART_TIME_QDELAY = 18'h516/18'd12;

  // 75Mhz  clock
  //	localparam UART_TIME_DELAY = 16'h1f4c/24;
  //	localparam UART_TIME_RDELAY = 18'hfa6/24;
  //	localparam UART_TIME_QDELAY = 18'h7d3/24;


  reg [2:0] in_pos;
  reg [7:0] i_data;
  reg [9:0] shiftin;
  reg [10:0] shiftout;

  reg fin;
  reg i_dout;
  reg sending;
  reg [13:0] delay;
  reg [2:0] istate;
  reg [15:0] uartcomp;
  reg [17:0] uartcount;

  reg [17:0] tx_baud_count;

  reg [17:0] rx_baud_count;

  reg [7:0] i_rec_data;


  reg [7:0] in_buffer [63:0] ;
  //	reg [7:0] out_buffer [15:0] ;

  reg [5:0] in_buffer_read_pos;
  reg [5:0] in_buffer_write_pos;


  //	reg [2:0] out_buffer_read_pos;
  //	reg [2:0] out_buffer_write_pos;


  assign rec_data = in_buffer[in_buffer_read_pos]; // i_rec_data;
  assign rec_valid = (in_buffer_read_pos != in_buffer_write_pos); //i_rec_valid;

  //  RECIEVE
  reg recclk;
  reg last_din;
  reg [3:0] reccount;
  reg [3:0] sendcount;

  reg sample_trigger;

  reg idle;

  assign dout = shiftout[sendcount];
  assign busy = sendcount < 4'd10 && send_request;

  
  /*
   *   Output
   */
  always @(posedge sclk)
  begin
    if(~reset)
      sendcount <= 4'd0;
    else
    begin
      if(send_request ==0)
      begin
        sendcount <= 4'd0;
        tx_baud_count <=0;
        shiftout <= 11'b11111111111;
      end
      else
      begin
        shiftout <= {1'b1,data,2'b01};
        if(tx_baud_count == UART_TIME_DELAY)
        begin
          if(sendcount < 4'd10)
            sendcount <= sendcount+4'h1;
          tx_baud_count <=0;
        end
        else
          tx_baud_count  <= tx_baud_count+18'b1;
      end
    end
  end

  
  
  reg pre_rr;
  
  always @( posedge sclk )
  begin
    if(~reset)
    begin
      in_buffer_read_pos<=0;
		pre_rr <=0;
    end
    else
    begin
      if(~pre_rr && rr && in_buffer_read_pos != in_buffer_write_pos)
        in_buffer_read_pos <= in_buffer_read_pos+6'b1;
		 pre_rr <=rr;
    end
  end

   reg  rx_clean;
	
  // 1. Two-stage synchroniser to prevent metastability
reg rx_sync0, rx_sync1;
always @(posedge sclk) begin
    rx_sync0 <= din;
    rx_sync1 <= rx_sync0;
end

// 2-bit filter: ignores any spike shorter than 40 nanoseconds
always @(posedge sclk) begin
    if (rx_sync0 == 1'b0 && rx_sync1 == 1'b0) begin
        rx_clean <= 1'b0;
    end else if (rx_sync0 == 1'b1 && rx_sync1 == 1'b1) begin
        rx_clean <= 1'b1;
    end
end

reg finish;

reg rx_clean_delayed;
always @(posedge sclk) rx_clean_delayed <= rx_clean;

wire rx_edge = (rx_clean != rx_clean_delayed); // High for 1 cycle when data changes

  /*
  *    Input
  */
  always @(posedge sclk)
  begin
    if(~reset)
    begin
      shiftin <= 9'h0;
      reccount<=  4'h0;
      in_buffer_write_pos<=0;
      idle <= 1;
		finish <= 0;
    end
    else
   if(finish)
   begin
     finish <= 0;
     if(rx_clean)
       idle <= 1;
     else
     begin
       shiftin <= 9'h0;
      reccount <= 4'h0;
      idle <= 0;
      rx_baud_count <= (UART_TIME_DELAY/18'd2);
     end
   end
 	 else
    if(idle && ~rx_clean) // Wait for start bit
    begin
      shiftin <= 9'h0;
      reccount<=  4'h0;
      idle <= 0;
      rx_baud_count <= (UART_TIME_DELAY/18'd2);
    end
    else
    begin
	    if (rx_edge) begin
 
        rx_baud_count <= (UART_TIME_DELAY/2);
		  end
		  else
      if(rx_baud_count == 0)
      begin
        rx_baud_count <=UART_TIME_DELAY;
        shiftin <= {rx_clean,shiftin[9:1]};
        if(reccount == 9)
        begin
          if(shiftin[9] & ~shiftin[0])
          begin
            in_buffer[in_buffer_write_pos] <= shiftin[8:1];
            in_buffer_write_pos <= in_buffer_write_pos+6'b1;
            reccount <= 4'h0;
            finish <= 1;
          end
        end
        else
          reccount <= reccount+4'b1;
      end
      else
        rx_baud_count  <= rx_baud_count-18'b1;
    end
  end


endmodule