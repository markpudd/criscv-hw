module sdramnew(
				input	  clk,
				input reset,
				input	[31:0]  address,
				input wire rw_req,
				input wire  rw,
				input wire[31:0] write_data,
				input wire[1:0] size,
				output wire[31:0] read_data,
				output data_valid,
					
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
				
localparam 	 INITIAL = 4'd0,
				 IDLE = 4'd1,
 				 ROW_ACTIVE = 4'd2 ,
 				 READ_COL = 4'd3,
				 WRITE_COL = 4'd4 ,
   			 MODE_SET = 4'd5,
				 AUTO_REFRESH = 4'd6,
				 NOP	 = 4'd7,
				 PRECHARGE = 4'd8,
				 AUTO_REFRESHS1=4'd9,				 
				 AUTO_REFRESHS2=4'd10,				 
				 DONE_RC=4'd11,
				 START=4'd12;
				 
localparam START_DELAY= 32'd5000; 				
localparam CAS_DELAY= 32'd1;   				
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
			  CMD_MRS    = 4'b0000; 	

localparam CMD_PALL_ADD = 13'b0010000000000;
localparam MRS_CONFIG_ADD = 13'b0001000100000;

reg [4:0] nState;
reg [4:0] cState;

reg [3:0] command;
reg [31:0] delay;
reg [31:0] dtarget;

reg irw;
reg irwq;
reg [1:0]isize;
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

assign column_address =  {3'b001,mem_address[10:1]};
assign row_address =  {mem_address[23:11]};
assign bank = mem_address[25:24];
assign odd=mem_address[0];

assign {dram_cs_n, dram_ras_n,dram_cas_n, dram_we_n}=  nop ? CMD_NOP:command;
assign dram_addr = (command==CMD_PALL) ? CMD_PALL_ADD :
						 (command==CMD_MRS)? MRS_CONFIG_ADD :
						 (command==CMD_ACT)? row_address :
						 column_address;
assign {dram_ba0,dram_ba1} = (command==CMD_MRS || command ==CMD_PALL) ? 2'b00 :bank;

assign dram_dqm = dqm;

assign dq =  (isize==2'h0) ? ((odd==1) ? {8'h0,dout[7:0]}: {dout[7:0],8'h0})
									: {dout[7:0],dout[15:8]};

assign dram_dq = (cState==WRITE_COL) ? dq : 16'bz;

assign data_valid = (cState==DONE_RC && ~first);

assign read_data =  (isize==2'h0) ? ((odd==1) ? {8'h0,din[7:0]}: {8'h0,din[15:8]})
									: (isize==2'h1) ? {din[7:0],din[15:8]} : {din[7:0],din[15:8],din[23:16],din[31:24]}  ;
									
assign dqm =  (isize==2'h0 && cState==WRITE_COL ) ? ((odd==1) ? 2'b10 : 2'b01)
								: 2'b00;

// Only one chip for time being			
assign dram_cke = 1'b1;
assign dram_cs_n = 1'b0;	

reg first;
		
// Deal with request
always@(posedge clk) begin
	if(~reset)
	begin
		irw<=0;
		first<=0;
	end
	else
	begin
		irwq =  0;
		if(rw_req==1 && address>= 32'h30000 && ~address[31])
		begin
			mem_address = (address-32'h30000);
		//	irwq<=1;
			isize = size;
			irw = rw;
			irwq = 1;
			if(isize == 2'h2) first = 1;
		end
		if(first && cState==DONE_RC) 
		begin
			mem_address = mem_address+2;
			irwq = 1;
			first = 0;
		end
	end
	
end


always@(posedge clk) begin
	if(~reset)
	begin
		cState <= START;
		delay<=0;
		nop<=1;
		//dtarget<=0;
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


always@(posedge clk) begin 
		if(nState == DONE_RC && (delay ==CAS_DELAY))
		   if(first) din[31:16] <=dram_dq;
			else  din[15:0] <=dram_dq ;
		if(nState == ROW_ACTIVE) dout <= write_data[15:0];
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
							if(irw) nState = WRITE_COL;
							else 
							begin
								nState = READ_COL;				
								
							end
						  end
		 READ_COL : begin
							command=CMD_READ;	
							nState = DONE_RC;	
							dtarget =CAS_DELAY;
					  end
		 WRITE_COL : begin
		 
							command=CMD_WRITE;	
							dtarget =0;
							nState = DONE_RC;
					  end
		DONE_RC: begin
						command=CMD_NOP;	
						if(irw) dtarget =TRC_DELAY;
						else dtarget =TRC_DELAY-CAS_DELAY;
						nState = IDLE;
					end
	endcase			
end

endmodule