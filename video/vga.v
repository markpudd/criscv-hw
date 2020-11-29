	// This is a LE Hog (prbly due to paletta and scalline buffer).....
	module vga(     input clk,	
					    input vclk,
						 input reset,
						 output wire [31:0] address,
						 output wire rw_req,
						 input wire[15:0] read_data,
						 output wire [7:0] burst_len,
						 input wire data_available,
						 input wire [7:0] cmd_byte,
						 input wire [9:0] cmd_address,
						 input wire cmd_write,
						 output cmd_done,
						 output sd_busy,
						 output [3:0]r,
						 output [3:0]g,
						 output [3:0]b,
						 output vsync,
						 output hsync);
	
	localparam H_VISABLE= 640; 	
	localparam H_FRONT_PORCH = 16; 	
	localparam H_SYNC_PULSE = 96; 	
	localparam H_BACK_PORCH = 48; 	
	localparam H_TOTAL = H_VISABLE+H_FRONT_PORCH+H_SYNC_PULSE+H_BACK_PORCH; 	


	localparam V_VISABLE= 480; 		
	localparam V_FRONT_PORCH = 10; 	
	localparam V_SYNC_PULSE = 2; 	
	localparam V_BACK_PORCH = 33; 	
	localparam V_TOTAL = V_VISABLE+V_FRONT_PORCH+V_SYNC_PULSE+V_BACK_PORCH; 
	
	localparam 	IDLE = 2'd0,
				   REQUEST_LINE = 2'd1,
					READ_DATA = 2'd2,
					DONE = 2'd3;
	
	
		localparam CMD_WRITE_DELAY= 2; 		

	//  We will use 8 bit pallete as likly to move this to HDMI
	// this is expensive
	reg [7:0] r_palette[0:255];
	reg [7:0] g_palette[0:255];
	reg [7:0] b_palette[0:255];

		
	reg [9:0] hpos;
	reg [9:0] vpos;
	
	reg [1:0] nState;
	reg [1:0] cState;
	
	// Start of frame in memory
	reg [31:0] t_frame_start;
	reg [31:0] frame_start;
	reg [31:0] frame_pos;

	
	//reg [15:0] scanline [63:0] ;
	
	// 2 scan lines
	reg [15:0] scanline [0:319] ;
	
	
	reg [8:0] scanline_pos;

	reg [3:0] no_burst;
	reg [3:0] back_off;

	
	reg req_burst;
	reg cmd_donel;
	wire [7:0]pr;
	wire [7:0]pg;
	wire [7:0]pb;

	wire [15:0] pixel;
	
	assign cmd_done =cmd_donel;
	
	assign burst_len = 8'd31;
	assign vsync = ((vpos > V_VISABLE+V_FRONT_PORCH) && (vpos < V_VISABLE+V_FRONT_PORCH+V_SYNC_PULSE)) ? 1'b0: 1'b1;
	assign hsync = ((hpos > H_VISABLE+H_FRONT_PORCH) && (hpos < H_VISABLE+H_FRONT_PORCH+H_SYNC_PULSE)) ? 1'b0: 1'b1;
	
	assign rw_req  = (cState== REQUEST_LINE) || (cState==READ_DATA) ;
	assign sd_busy  = (cState== REQUEST_LINE) || (cState==READ_DATA) ;
	assign address = frame_pos;
	
	// Scan line doubler
	assign pixel = (hpos> H_VISABLE || vpos >V_VISABLE) ? 0 : vpos[1]==0 ? scanline[hpos[9:2]] : scanline[hpos[9:2]+160];
	
	
//	assign r = !hpos[1] ? pixel[15:13] : pixel[7:5];
//	assign g = !hpos[1] ? pixel[12:10] : pixel[4:2];
//	assign b = !hpos[1] ? {pixel[9:8],1'b0} : {pixel[1:0],1'b0};
	
	
	// Read MSB from palette 
	wire [7:0] lu;
	assign lu = !hpos[1] ? pixel[15:8] : pixel[7:0];
	
	assign pr = r_palette[lu];
	assign pg = g_palette[lu];
	assign pb = b_palette[lu];

	
	
	assign r = pr[7:4];
	assign g = pg[7:4];
	assign b = pb[7:4];
//	assign g = pix_pos[5:3];
//	assign b = pix_pos[8:6];
//	assign r = pix_pos[2:0];
//	assign g = pix_pos[5:3];
//	assign b = pix_pos[8:6];
	
	
	always@(posedge clk) begin
		if(~reset)
		begin
			frame_start<=32'hC00300;
			cmd_donel<=0;
		end
		else 
		begin
			if( cmd_donel==1)
				 cmd_donel<=0;
			else if(cmd_write)
			begin
				case(cmd_address[9:8])
				 2'b00: begin
							 r_palette[cmd_address[7:0]] <= cmd_byte;
							 cmd_donel<=1;
						  end
				 2'b01: begin
							 g_palette[cmd_address[7:0]] <= cmd_byte;
							 cmd_donel<=1;
						  end
				 2'b10: begin
							 b_palette[cmd_address[7:0]] <= cmd_byte;
							 cmd_donel<=1;
						  end
				 2'b11: begin
							 // Atomic frame addressz switch
							 if(cmd_address[3] && cmd_byte[0]) begin
								frame_start<=t_frame_start;
							 end else 
							 begin
							 case(cmd_address[1:0]) 
								2'b00: begin
											t_frame_start[31:24] <= cmd_byte;
										 end
								2'b01: begin
										   t_frame_start[23:16] <= cmd_byte;
									   end
								2'b10: begin
											t_frame_start[15:8] <= cmd_byte;
										 end
								2'b11: begin
											t_frame_start[7:0] <= cmd_byte;
										 end
								endcase
								cmd_donel<=1;
							end
						end
				endcase
			end
		end
		end
		
	always@(posedge vclk) begin
		if(~reset)
		begin
			hpos <= 0;
			vpos <=0;
		end
		else
		begin
			if(hpos == H_TOTAL) 
			begin
				hpos<=0;
				if(vpos == V_TOTAL) vpos<=0;
				else vpos <= vpos+10'h1;
	
			end
			else hpos <= hpos+10'h1;
		end
	end

	always@(posedge clk) begin
		if(~reset)
		begin
			scanline_pos=0;
			frame_pos <= 32'hC00404;
			no_burst<=5;
		end
		else
		begin
			if(cState == IDLE && hpos ==0 && vpos ==V_TOTAL-2 ) begin
				frame_pos <= 32'hC00404;
				scanline_pos=0;
				req_burst <=1;
				no_burst<=5;
			end
			if(cState == IDLE && hpos ==0 && vpos[1]==0  && vpos[0]==0  && vpos <V_VISABLE) begin
				scanline_pos=160;
				req_burst <=1;
				no_burst<=5;
			end
			if(cState == IDLE && hpos ==0 && vpos[1]==1 && vpos[0]==0 && vpos <V_VISABLE) begin
				scanline_pos=0;
				req_burst <=1;
				no_burst<=5;
			end
			if(cState == IDLE && no_burst!=0 ) req_burst <=1;

		   if(cState == READ_DATA) begin
					req_burst <=0;
					scanline[scanline_pos] <= read_data;
					scanline_pos = scanline_pos+10'h1;
			end 
		   if(cState == DONE) begin
				frame_pos<=frame_pos+32'd64;
				if(no_burst !=0) no_burst<=no_burst-4'b1;
			end 
		end
	end

// FSM
always@(posedge clk) begin
	if(~reset)
	begin
		cState = IDLE;
	end
	else
			cState <= nState;
end



	// Memeory burst FSM
	always@ ( * ) begin
		case(cState)
			 IDLE: begin
						if(req_burst) nState = REQUEST_LINE;
						else nState = IDLE;
					 end
			 REQUEST_LINE:
					 begin
						if(data_available) nState = READ_DATA;
						else nState = REQUEST_LINE;
					 end	
			 READ_DATA:
					 begin
						if((scanline_pos & 10'h1f) == 10'h1f ) nState = DONE;
						else nState = READ_DATA;
					 end	
			 DONE:
					 begin
						nState = IDLE;
					 end	
		endcase
	end			

	
endmodule