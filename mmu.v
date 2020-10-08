/*  Super simple (and slightly rubbish) SRAM MMU,  there is massive optimzations that could be done for this:-
			*  Caching would substabtialy speed the whole thing up 
			*  Bigger reads - Currently using 16-bit memory - the built in Cyclone memory can deliver 256 bits at a time
			*  Use Cyclone dual port to optimizes instruction vs data
			*  Don't allow byte addresses (unless the byte commands)
			*  Add pre-fetch (likely next read is last read (pc) +4
*/
module mmu(input clk,
				input mclk,
				input cclk,
				 input reset,
				 input wire [31:0] address,
				 input wire rw_req,
				 input wire  rw,
				 input wire[31:0] write_data,
				 input wire[1:0] size,
				 output wire[31:0] read_data,
				 output data_valid,
						 
						 
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
			
	localparam 	D_BYTE_EVEN ={2'h0,1'b0},
					D_BYTE_ODD = {2'h0,1'b1},
					D_HALF_EVEN ={2'h1,1'b0},
					D_HALF_ODD = {2'h1,1'b1},
					D_WORD_EVEN ={2'h2,1'b0},
					D_WORD_ODD = {2'h2,1'b1};

	localparam 	IDLE =3'h0,
					HALF_ODD_P2 =3'h1,
					WORD_EVEN_P2 =3'h2,
					WORD_ODD_P2 =3'h3,
					WORD_ODD_P3 =3'h4,
					DONE=3'h5,
					DR=3'h6;

	reg [3:0] nState;
	reg [3:0] cState;
	reg [3:0] pState;

				 
	reg [31:0]i_read_data;
	
	wire [1:0] be;	
	wire  [31:0] br_address;

	wire [15:0] br_data;
	wire		 br_wren;

	wire [15:0] br_q;
	wire m_data_valid;
	
	wire mem_req;


	wire [2:0] req_type;

	assign req_type={size,address[0]};
	
	
	memcache memcache( .clk(clk),
				       .mclk(mclk),
				       .cclk(cclk),
						 .ce(ce),
						 .reset(reset),
						 .address(br_address),
						.be(be),
						.rw_req(mem_req),
						.write_data(br_data),
						.rw(br_wren),
						.read_data(br_q),
						.data_valid(m_data_valid),
						 
					.dram_dq(dram_dq),
					.dram_addr(dram_addr),
					.dram_dqm(dram_dqm),
					.dram_cke(dram_cke),
					.dram_we_n(dram_we_n),
					.dram_cas_n(dram_cas_n),
					.dram_ras_n(dram_ras_n),
					.dram_cs_n(dram_cs_n),
					.dram_ba0(dram_ba0),
					.dram_ba1(dram_ba1));	
				
	
assign ce = (address[31]==0  && address >= 32'h10000);
	

	
assign br_address = (cState == IDLE) ? address :
						  (cState == WORD_ODD_P3) ? address+32'h4 :
						  address+32'h2;
						  
						  
assign mem_req = (rw_req && ce && cState !=DONE && cState!=DR);
assign br_wren = 	(rw_req && ce && rw);

/*
 *  These can be reduced but for ease of readabilty keep them full for now
 */
assign be = 	  (rw & cState == IDLE && req_type == D_BYTE_EVEN) ? 2'b10 :
					  (rw & cState == IDLE && req_type == D_BYTE_ODD) ? 2'b01 :
					  (rw & cState == IDLE && req_type == D_HALF_EVEN) ?2'b11 :
					  (rw & cState == IDLE && req_type == D_HALF_ODD) ? 2'b01 :
					  (rw & cState == IDLE && req_type == D_WORD_EVEN) ? 2'b11 :
					  (rw & cState == IDLE && req_type == D_WORD_ODD) ? 2'b01 :
					  (rw & cState == HALF_ODD_P2) ? 2'b10:
					  (rw & cState == WORD_EVEN_P2) ?2'b11 :
					  (rw & cState == WORD_ODD_P2) ? 2'b11 :
					  (rw & cState == WORD_ODD_P3 ) ? 2'b10 : 2'b11;
					  
assign br_data = (cState == IDLE && req_type == D_BYTE_EVEN) ? {write_data[7:0],8'h0} :
					  (cState == IDLE && req_type == D_BYTE_ODD) ?  {8'h0,write_data[7:0]} :
					  (cState == IDLE && req_type == D_HALF_EVEN) ? {write_data[7:0],write_data[15:8]} :
					  (cState == IDLE && req_type == D_HALF_ODD) ? {8'h0,write_data[7:0]} :
					  (cState == IDLE && req_type == D_WORD_EVEN) ? {write_data[7:0],write_data[15:8]} :
					  (cState == IDLE && req_type == D_WORD_ODD) ? {8'h0,write_data[7:0]}  :
					  (cState == HALF_ODD_P2) ? {write_data[15:8],8'h0}  :
					  (cState == WORD_EVEN_P2) ? {write_data[23:16],write_data[31:24]} : 
					  (cState == WORD_ODD_P2) ?  {write_data[15:8],write_data[23:16]} :
					  (cState == WORD_ODD_P3 ) ?  {write_data[31:24],8'h0}  : 16'h0;

assign read_data = i_read_data;


assign data_valid = (cState == DONE);

always@ ( posedge clk ) begin
		if( !mem_req) i_read_data <= 32'h0;
		if(cState == IDLE && req_type == D_BYTE_EVEN) i_read_data <= {i_read_data[31:8],br_q[15:8]};
		if(cState == IDLE && req_type == D_BYTE_ODD)   i_read_data <= {i_read_data[31:8],br_q[7:0]};
		if(cState == IDLE && req_type == D_HALF_EVEN)   i_read_data <= {i_read_data[31:16],br_q[7:0],br_q[15:8]};
		if(cState == IDLE && req_type == D_HALF_ODD)   i_read_data <=   {i_read_data[31:8],br_q[7:0]};
		if(cState == IDLE && req_type == D_WORD_EVEN)   i_read_data <=  {i_read_data[31:16],br_q[7:0],br_q[15:8]};
		if(cState == IDLE && req_type == D_WORD_ODD)   i_read_data <= {i_read_data[31:8],br_q[7:0]};
		if(cState == HALF_ODD_P2)   i_read_data <=  {i_read_data[31:16],br_q[15:8],i_read_data[7:0]};
		if(cState == WORD_EVEN_P2)   i_read_data <= 	{br_q[7:0],br_q[15:8],i_read_data[15:0]}; 
		if(cState == WORD_ODD_P2)  i_read_data <= {i_read_data[31:24],br_q[7:0],br_q[15:8],i_read_data[7:0]};
		if(cState == WORD_ODD_P3 )  i_read_data <=  {br_q[7:0],i_read_data[23:0]};
end		 
						 
			  
always@(posedge clk) begin
	if(~reset)
	begin
		cState = IDLE;
	end
	else
	begin
		if(m_data_valid || cState ==DONE ||cState==DR) begin
			pState = cState;
			cState= nState;
		end
	end
end
	
	
always@ ( * ) begin
		 case(cState)
			 IDLE: begin
						if(rw_req && ce) begin
							case(req_type)
								D_BYTE_EVEN: nState=DONE;
								D_BYTE_ODD: nState=DONE;
								D_HALF_EVEN: nState=DONE;
								D_HALF_ODD: nState=HALF_ODD_P2;
								D_WORD_EVEN: nState=WORD_EVEN_P2;
								D_WORD_ODD: nState=WORD_ODD_P2;
								default: nState=IDLE;
							endcase
						end 
						else
						nState=IDLE;
					 end
			 HALF_ODD_P2: begin
							nState = DONE ;
						 end
			 WORD_EVEN_P2: begin
							 nState = DONE; 
						 end
			 WORD_ODD_P2: begin
							 nState = WORD_ODD_P3; 
						 end	
			 WORD_ODD_P3: begin
						  nState = DONE; 
						 end	
   		DONE: begin
						nState = DR; 
					 end		
   		DR: begin
						nState = IDLE; 
					 end		
			
		endcase
end
	
	

endmodule