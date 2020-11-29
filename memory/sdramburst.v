module sdramburst (
				input	  clk,
				input	  ce,
				input reset,
				input	[31:0]  address,
				input wire rw_req,
				input wire  rw,
				input wire[15:0] write_data,
				output wire[15:0] read_data,
				input wire[7:0] burst_len,
				output data_bursting,
					
				input  mclk,
				inout [15:0] dram_dq,
				output wire [12:0] dram_addr,
				output wire [1:0] dram_dqm,
				output wire dram_cke,
				output wire dram_we_n,
				output wire dram_cas_n,
				output wire dram_ras_n,
				output wire dram_cs_n,
				output wire dram_ba0,
				output wire dram_ba1);
				
localparam 	 INITIAL = 5'd0,
				 IDLE = 5'd1,
 				 ROW_ACTIVE = 5'd2 ,
 				 READ_COL = 5'd3,
				 WRITE_COL = 5'd4 ,
   			 MODE_SET = 5'd5,
				 AUTO_REFRESH = 5'd6,
				 NOP	 = 5'd7,
				 PRECHARGE = 5'd8,
				 AUTO_REFRESHS1=5'd9,				 
				 AUTO_REFRESHS2=5'd10,				 
				 DONE_RC=5'd11,
				 START=5'd12,
				 CLOSE_ROW=5'd13,	
				 BURST_TERM=5'd14,
				 READ_COLB=5'd15,
				 WRITE_COLB=5'd16,	
				 READ_COLA=5'd17;	
				 
localparam START_DELAY= 32'd5000; 				
localparam CAS_DELAY= 32'd2;   				
localparam BANK_DELAY= 32'd2; 		 
localparam TRC_DELAY=32'd8;
localparam TMRD_DELAY=32'd1;

localparam CMD_NOP    = 4'b0111,
			  CMD_READ   = 4'b0101,
			  CMD_WRITE  = 4'b0100,
			  CMD_ACT    = 4'b0011,
			  CMD_PRE    = 4'b0010,
			  CMD_PALL   = 4'b0010,
			  CMD_REF    = 4'b0001,
			  CMD_MRS    = 4'b0000, 	
			  CMD_TERM   = 4'b0110; 	

localparam CMD_PALL_ADD = 13'b0010000000000;
localparam MRS_CONFIG_ADD = 13'b0000000100111;
localparam BURST_LEN = 5'd31;
localparam WRITE_DELAY=1;

reg [4:0] nState;
reg [4:0] cState;

reg [3:0] command;
reg [31:0] delay;
reg [31:0] dtarget;
reg [4:0] burst;

reg irw;
reg irwq;
reg dv;

reg [31:0] din;
reg [15:0] dout;
wire [15:0] dq;
wire [1:0] dqm;

reg [31:0] mem_address;
wire [1:0] bank;
wire [12:0] row_address;
wire [12:0] column_address;
wire odd;
reg nop;



assign column_address =  {3'b0000,mem_address[9:1]};
assign row_address =  {mem_address[22:10]};
assign bank = mem_address[24:23];
assign odd=mem_address[0];

assign data_bursting =(cState==WRITE_COL || cState==WRITE_COLB || cState==READ_COLB|| cState==READ_COLA );

assign {dram_cs_n, dram_ras_n,dram_cas_n, dram_we_n}=  nop ? CMD_NOP:command;

assign dram_addr = (command==CMD_PALL) ? CMD_PALL_ADD :
						 (command==CMD_MRS)? MRS_CONFIG_ADD :
						 (command==CMD_ACT)? row_address :
						 column_address;
						 
assign {dram_ba0,dram_ba1} = (command==CMD_MRS || command ==CMD_PALL) ? 2'b00 :bank;

assign dram_dqm = 2'b00;
									
assign dram_dq = (cState==WRITE_COL) ? write_data : 16'bz;

assign read_data =  dram_dq ;
									

// Only one chip for time being			
assign dram_cke = 1'b1;
assign dram_cs_n = 1'b0;	


reg wc;
		
// Deal with request
always@(posedge clk) begin
	if(~reset)
	begin
		irw<=0;
		irwq <=  0;
		burst <=0;
	end
	else
	begin
		if(cState==ROW_ACTIVE) 
		begin
			irwq <= 0;
			burst <= BURST_LEN;
		end
		if(cState==WRITE_COL || cState==READ_COLB)
			burst<=burst-5'h1;
		if(cState==IDLE && rw_req==1 && ce)
		begin
			mem_address = (address-32'h10000);
			irw <= rw;
			irwq <= 1;
		end 
	end
end


always@(posedge clk) begin
	if(~reset)
	begin
		cState = START;
		delay=0;
		nop=1;
	end
	else
		if(delay == dtarget) begin
			cState <= nState;
			nop<=0;
			delay<=0;
		end
		else begin
			delay <= delay +1;
			nop<=1;
		end
end



always@ ( * ) begin
	 dtarget = 0;
	 
	 case(cState)

		 START: begin
		 				command=CMD_NOP;
						dtarget = 0;
						nState = INITIAL ;
					end
		 INITIAL: begin
						command=CMD_NOP;
						dtarget = START_DELAY;
						nState = PRECHARGE ;
					 end
		 PRECHARGE : begin
						command=CMD_PALL;
						dtarget = CAS_DELAY;
						nState = AUTO_REFRESHS1;
					   end
		 AUTO_REFRESHS1 : begin
						command=CMD_REF;
						dtarget =TRC_DELAY;
						nState = AUTO_REFRESHS2;
						end
		 AUTO_REFRESHS2 : begin
						command=CMD_REF;
						dtarget =TRC_DELAY;
						nState = MODE_SET;
						end					
		 MODE_SET : begin
						command=CMD_MRS;
						dtarget =TMRD_DELAY;
						nState = IDLE;
					  end
		 AUTO_REFRESH : begin
		 				command=CMD_REF;
						dtarget =TRC_DELAY;
						nState = IDLE;
					
				  end
		 IDLE : begin
					dtarget =0;
					command=CMD_NOP;
					if(irwq) nState = ROW_ACTIVE;
					else nState = AUTO_REFRESH;
					 end						
		 ROW_ACTIVE : begin
							dtarget =0;	
							command=CMD_ACT;	
							dtarget = BANK_DELAY;
							if(irw) nState = WRITE_COLB;
							else 
							begin
								nState = READ_COL;				
								
							end
						  end
		 READ_COL : begin
					command=CMD_READ;	
					nState = READ_COLA;	
					dtarget =0;
			  end
		 READ_COLA : begin
			command=CMD_NOP;	
			nState = READ_COLB;	
			dtarget =CAS_DELAY-1;
	  end
		 READ_COLB : begin
			//				if(burst ==BURST_LEN)
			//					command=CMD_READ;
			//				else
								command=CMD_NOP;	
							if(burst ==0)
							begin
								nState = BURST_TERM;	
								dtarget =0;
							end
							else nState=READ_COLB;
					  end
		 WRITE_COLB : begin
					command=CMD_NOP;	
					nState = WRITE_COL;	
					dtarget =WRITE_DELAY;
				end
		 WRITE_COL : begin
							if(burst == BURST_LEN)
								command=CMD_WRITE;
							else
								command=CMD_NOP;
							if(burst ==0)
							begin
								dtarget =0;
								nState = BURST_TERM;
							end
							else nState=WRITE_COL;
					  end
		BURST_TERM: begin
							command=CMD_TERM;	
							nState = CLOSE_ROW;
						end
		CLOSE_ROW:
						begin
							command=CMD_PRE;	
							nState = DONE_RC;
						end
		DONE_RC: begin
						command=CMD_NOP;	
						dtarget =TRC_DELAY;
						nState = AUTO_REFRESH;
					end
	endcase	
	if(nop)
		command=CMD_NOP;
end

endmodule