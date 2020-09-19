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

   // 9600
//	localparam UART_TIME_DELAY = 16'h1458; 						
//	localparam UART_TIME_RDELAY = 18'ha2c; 
//	localparam UART_TIME_QDELAY = 18'h516; 

	  // 38400
	localparam UART_TIME_DELAY = 16'h1458/4; 						
	localparam UART_TIME_RDELAY = 18'ha2c/4; 
	localparam UART_TIME_QDELAY = 18'h516/4; 


	
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
		
	

	
	assign rec_data = i_rec_data;
	assign rec_valid = i_rec_valid;

		//  RECIEVE
	reg recclk;
	reg last_din;
	reg [3:0] reccount;
	reg [3:0] sendcount;
	
	
	
	
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
	
	
	always @(posedge ss,negedge reset)
	begin
		if(~reset)
			shiftout = 11'b11111111111;
		else
			shiftout = {1'b1,data,2'b01};
	end
	
	assign dout = shiftout[sendcount];
	assign busy = sendcount != 4'd10;
	
	

	
	

	always @(posedge recclk, negedge reset,posedge rr)
	begin
		if(~reset)
		begin
			shiftin = 9'h0;
			reccount= 0;
		end
		else
		begin
			if(rr)
				i_rec_valid=0;
			else
			begin
				shiftin = {din,shiftin[9:1]};
				if(reccount == 9) 
				begin
					if(shiftin[9] & ~shiftin[0])
					begin
						i_rec_data = shiftin[8:1];
						i_rec_valid=1'b1;
						reccount = 4'h0;
					end
				end
				else
					reccount = reccount+4'b1;	
			end
		end
	end
		
	
endmodule