
	module uart(input wire sclk,
					output dout,
				   input reset,
				   input wire ss,
				   input wire [7:0] data,
					output wire busy,
					output wire [7:0] rec_data,
					output wire rec_valid,
					input wire din,
					input wire rr);


	localparam UART_TIME_DELAY = 16'h1458/24;				
	localparam UART_TIME_RDELAY = 18'ha2c/24;
	localparam UART_TIME_QDELAY = 18'h516/24;


	
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
	
	reg [7:0] i_rec_data;
	reg i_rec_valid;
		
	reg [7:0] in_buffer [0:15] ;
//	reg [7:0] out_buffer [15:0] ;

	reg [2:0] in_buffer_read_pos;
	reg [2:0] in_buffer_write_pos;
	

//	reg [2:0] out_buffer_read_pos;
//	reg [2:0] out_buffer_write_pos;

	
	assign rec_data = in_buffer[in_buffer_read_pos]; // i_rec_data;
	assign rec_valid = (in_buffer_read_pos != in_buffer_write_pos); //i_rec_valid;

		//  RECIEVE
	reg recclk;
	reg last_din;
	reg [3:0] reccount;
	reg [3:0] sendcount;
	
	
	
	/*
	*    Clock Generation
	*/
	always @(posedge sclk,negedge reset)
	begin
		if(~reset)
		begin
			recclk = 0;
			uartcount = 0;
		end
		else
		begin
			// Sync clock falling on edge
			if(din & (last_din != din)) 
			begin
				uartcount= UART_TIME_QDELAY;
				recclk = 0;
			end
			else
			begin
				
				if(uartcount ==0)
				begin
					recclk = ~recclk;
					uartcount = UART_TIME_RDELAY;
				end
				else
					uartcount = uartcount-18'b1;
			end
			last_din = din;
		end
	end		

	reg finish;
	

	/*
	 *   Output
	 */
	always @(posedge recclk,posedge ss,negedge reset)
	begin
		if(~reset)
			sendcount = 4'd10;
		else
			if(ss) 
				sendcount=0;
			else
			if(sendcount != 4'd10)
				sendcount = sendcount+4'h1;
			else
				sendcount = 4'd10;
	end
	
	
	/*
	 *   Output
	 */
	always @(posedge ss,negedge reset)
	begin
		if(~reset)
			shiftout = 11'b11111111111;
		else
			shiftout = {1'b1,data,2'b01};
	end
	
	assign dout = shiftout[sendcount];
	assign busy = sendcount != 4'd10;
	
	
	always @( posedge rr,negedge reset)
	begin
		if(~reset)
		begin
			in_buffer_read_pos=0;
		end
		else
		begin
			if(in_buffer_read_pos != in_buffer_write_pos)
					in_buffer_read_pos = in_buffer_read_pos+1;
		end
	end
	
	
	/*
	*    Input
	*/
	always @(posedge recclk, negedge reset)
	begin
		if(~reset)
		begin
			shiftin <= 9'h0;
			reccount=  4'h0;
			i_rec_valid=0;
			in_buffer_write_pos=0;
		end
		else
		begin
			shiftin <= {din,shiftin[9:1]};
			if(reccount == 9) 
			begin
				if(shiftin[9] & ~shiftin[0])
				begin
				//	i_rec_data = shiftin[8:1];
					i_rec_valid=1'b1;
					in_buffer[in_buffer_write_pos] = shiftin[8:1];
					in_buffer_write_pos = in_buffer_write_pos+1;
					reccount = 4'h0;
				end
			end
			else
				reccount = reccount+4'b1;	
		end
	end
	
	
	
endmodule