/*  Super simple  MMU,  there is massive optimzations that could be done for this:-
			*  Bigger reads - Currently using 16-bit memory - the built in Cyclone memory can deliver 256 bits at a time
			*  Use Cyclone dual port to optimizes instruction vs data
			*  Add pre-fetch (likely next read is last read (pc) +4
*/
module mmu(input clk,
				 input reset,
				 
				 input wire [31:0] address,

				 input wire  rw,
				 input wire[31:0] write_data,
				 input wire[1:0] size,
				 output wire[31:0] read_data,
				 
				 input wire       m_valid,  // master valid
				 output          s_valid,  // slave valid
				 
				output wire	  sd_ce,
				output wire	[31:0]  sd_address,
				output wire sd_rw_req,
				output wire  sd_rw,
				output wire[15:0] sd_write_data,
				output wire[7:0] sd_burst_len,
				input wire[15:0] sd_read_data,
				input wire sd_data_bursting);
	
	parameter LOW_RAM_WIDTH =13;	
	
	

	localparam 	IDLE =3'h0,

					DONE=3'h5;



	reg [3:0] nState;
	wire [3:0] be_mask;

	reg [2:0] mdelay;
				 

	wire ce;
	wire cel;
	wire [3:0] be;	
	wire  [31:0] br_address;

	wire [31:0] br_data;
	wire		 br_wren;
	wire		 br_lwren;
	wire		 br_hwren;
	wire [LOW_RAM_WIDTH:0]	ram_address;
	wire [31:0] br_q;
	wire [31:0] lbr_q;
	wire [31:0] hbr_q;
	
	wire m_data_valid;
	wire mc_data_valid;
	wire cache_busy;
	reg ml_data_valid;
	
	wire mem_req;
   reg lm_v;

	 
	wire [2:0] req_type;

	assign req_type={size,address[0]};
	assign sd_ce = ce;
	
	memcache memcache( .clk(clk),
						 .ce(ce),
						 .reset(reset),
						 .address(br_address),
						.be(be),
						.rw_req(mem_req),
						.write_data(br_data),
						.rw(br_hwren),
						.read_data(hbr_q),
						.data_valid(mc_data_valid),
						.busy(cache_busy),
						
						.sd_address(sd_address),
						.sd_rw_req(sd_rw_req),
						.sd_rw(sd_rw),
						.sd_write_data(sd_write_data),
						.sd_read_data(sd_read_data),
						.sd_burst_len(sd_burst_len),
						.sd_data_bursting(sd_data_bursting));

	ram ram(.address(ram_address),
				.byteena(be),
				.clock(clk),
				.data(br_data),
				.wren(br_lwren),
				.q(lbr_q));
	
	
assign br_q = ce ?	hbr_q : lbr_q;

assign br_hwren = br_wren && ce;
assign br_lwren = br_wren && cel;

assign ram_address = br_address[LOW_RAM_WIDTH+1:2];
assign ce = (address[31]==0  && address >= 32'h10000);
assign cel = (address[31]==0  && address < 32'h10000);
	
	
assign br_address =  address;
						  
						  
assign mem_req = (m_valid && ce );
assign br_wren = 	(m_valid && rw );//&& cState !=DONE );

//assign m_data_valid = ce ? mc_data_valid : ml_data_valid;


assign s_valid = (ce ? mc_data_valid : lm_v ) & m_valid;


//assign m_valid = (cState != IDLE);

assign be_mask = (size == 0) ? 4'b0001 : 
					  (size == 1) ? 4'b0011 :
					                4'b1111;
//
/*
 *  These can be reduced but for ease of readabilty keep them full for now
 */
assign be = 	be_mask << address[1:0];
					  
assign br_data =  (size ==0) ? {4{write_data[7:0]}} :
						(size == 1) ? {2{write_data[15:0]}} :
						write_data;
						
						
/*
(cState == IDLE && req_type == D_BYTE_EVEN) ? {write_data[7:0],8'h0} :
					  (cState == IDLE && req_type == D_BYTE_ODD) ?  {8'h0,write_data[7:0]} :
					  (cState == IDLE && req_type == D_HALF_EVEN) ? {write_data[7:0],write_data[15:8]} :
					  (cState == IDLE && req_type == D_HALF_ODD) ? {8'h0,write_data[7:0]} :
					  (cState == IDLE && req_type == D_WORD_EVEN) ? {write_data[7:0],write_data[15:8]} :
					  (cState == IDLE && req_type == D_WORD_ODD) ? {8'h0,write_data[7:0]}  :
					  (cState == HALF_ODD_P2) ? {write_data[15:8],8'h0}  :
					  (cState == WORD_EVEN_P2) ? {write_data[23:16],write_data[31:24]} : 
					  (cState == WORD_ODD_P2) ?  {write_data[15:8],write_data[23:16]} :
					  (cState == WORD_ODD_P3 ) ?  {write_data[31:24],8'h0}  : 16'h0;
*/


assign read_data  = br_q >> {address[1:0], 3'b000};
//assign read_data = i_read_data;


/*
always@ ( posedge clk ) begin
		if( ~mem_req) i_read_data <= 32'h0;
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
						 */


parameter RAM_DELAY =0;	
	
always@ ( posedge clk) begin
  if(~reset)
  begin
	  mdelay <= RAM_DELAY;
	  lm_v <=0;
	end
	if(m_valid && address[31]==0) begin
		if(mdelay == 0)
			lm_v <= 1;
		else
			mdelay <= mdelay -1;
	end else
	begin
		mdelay <= RAM_DELAY;
		lm_v <=0;
	end
end
	
	

endmodule