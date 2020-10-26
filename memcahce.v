module memcache(input clk,
				input mclk,
				input cclk,
				 input wire  ce,
						 input reset,
						 input wire [31:0] address,
						 input wire [1:0] be,
						 input wire  rw_req,
						 input wire  rw,
						 input wire[15:0] write_data,
						 output wire[15:0] read_data,
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
						 
localparam 	 IDLE = 4'd0,
				 REQUEST = 4'd1,
 				 CACHE_CHECK = 4'd2 ,
 				 DATA_IO = 4'd3,
				 STORE_PAGE = 4'd4 ,
   			 LOAD_PAGE = 4'd5,
				 DATA_FINISH = 4'd6,
				 DATA_WAIT = 4'd7,
					CACHE_CHECK_PRE= 4'd8,
										CACHE_CHECK_PRE2= 4'd9,
										LOAD_PREP=4'd10;
// Cache page size
localparam   PAGE_SIZE=31;
// Total chahe row (x2 as 2 associative)
localparam   CACHE_SIZE=256;
localparam READ_DELAY=2;
reg [4:0] nState;
reg [4:0] cState;

wire [4:0] cache_offset;
wire [6:0] cache_set;
wire [14:0] cache_tag;
wire [15:0] c_q;
wire [15:0] cl_q;
wire [15:0] c_data;
wire [15:0] cl_data;
wire [31:0] sd_address;
wire [15:0] sd_read_data;
wire [15:0] sd_write_data;

wire [12:0]  c_address;
wire [8:0]  cl_address;
wire [12:0] cache_data_base;
wire [12:0] cache_data_address;
reg [5:0] a_count;
wire sd_rw;
wire sd_rw_req;
wire sd_bursting;

wire c_wren;
wire cl_wren;
wire [1:0]c_be;
wire [1:0]cl_be;
wire fsm_clk;

// latch inputs on clock
//reg irw;
//reg [1:0]ibe;
//reg [15:0] iwrite_data;
//reg [31:0] iaddress;
reg [14:0] old_tag;
reg tag_index;
reg tag_hit;

assign cache_offset = address[5:1];
assign cache_set = address[12:6];
assign cache_data_base =  {cache_set,5'b0}; // | tag_index;
assign cache_data_address =  cache_data_base+cache_offset;

// Reduce total available ram to 1GB as
// sdram width is 16 and we don't want do 2 reads
// On systems requiring more than 1GB we would proabaly have a wider dq
assign cache_tag = address[27:13];
assign sd_address = (cState  == STORE_PAGE) ? {4'h0 ,cl_q[15:1],cache_set,6'h0}: {4'h0 ,cache_tag,cache_set,6'h0};

assign read_data = c_q ;						  
assign sd_write_data = c_q;
assign sd_rw = (cState  == STORE_PAGE) ;
assign sd_rw_req= (cState  == LOAD_PAGE) |(cState  == STORE_PAGE);

assign c_address = (cState != LOAD_PAGE && cState != STORE_PAGE) ? cache_data_address : cache_data_base+a_count[4:0];
assign c_data =(cState != LOAD_PAGE && cState != STORE_PAGE) ?  write_data :sd_read_data;
//assign c_wren = (cState  == LOAD_PAGE) | (irw && (cState == DATA_IO || cState==DATA_WAIT));
assign c_wren = (cState  == LOAD_PAGE) | (rw && (cState == DATA_FINISH));
assign c_be = (cState != LOAD_PAGE && cState != STORE_PAGE)  ? be : 2'b11;


assign cl_address = {cache_set,1'b0};
assign cl_data= {cache_tag,1'b0};
assign cl_wren=( cState  == DATA_FINISH);


assign data_valid = (cState == DATA_FINISH);


// Slow clock for sdram
assign fsm_clk =  (cState == IDLE ||
						cState == REQUEST ||
						cState == CACHE_CHECK ||	
						cState == DATA_WAIT ||
						cState == DATA_FINISH ||
						cState ==  DATA_IO) ? clk : cclk;
						
cache cache(.address(c_address),
						.byteena(c_be),
						.clock(fsm_clk),
						.data(c_data),
						.wren(c_wren),
						.q(c_q));

cachelookup cachelookup(.address(cl_address),
			//			.byteena(cl_be),
						.clock(fsm_clk),
						.data(cl_data),
						.wren(cl_wren),
						.q(cl_q));
						
sdramburst sdramburst( .clk(cclk),
						.ce(ce),
					    .reset(reset),
						 .address(sd_address),
						 .rw_req(sd_rw_req),
						 .rw(sd_rw),
						 .write_data(sd_write_data),
						 .read_data(sd_read_data),
						 .data_bursting(sd_bursting),
						 
					.mclk(mclk),
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
						 
				
					
					
always@(posedge fsm_clk) begin
	if(~reset)
	begin
		cState = IDLE;
	end
	else
	begin
		cState <= nState;
	end
end


always@(posedge fsm_clk) begin	
	if(cState == CACHE_CHECK) a_count =0;
	if(cState ==  LOAD_PREP) a_count =-1;
	else if(sd_bursting && (cState == LOAD_PAGE || cState == STORE_PAGE))
		a_count=a_count+6'd1;
end


always@ ( * ) begin
	 case(cState)
		 IDLE: begin
				if(rw_req && ce) nState = CACHE_CHECK_PRE;
					else nState = IDLE ;
				 end
		 REQUEST: begin
						nState = CACHE_CHECK_PRE ;
					 end
		CACHE_CHECK_PRE: begin      //  wait cl read
						nState = CACHE_CHECK ;
					 end				 
		 CACHE_CHECK: begin
					if(cache_tag == cl_q[15:1])	nState = DATA_FINISH;
					else if(cl_q[15:1] == 0) nState = DATA_FINISH;
					else nState = STORE_PAGE; 
					 end
		 DATA_IO: begin
						nState = DATA_WAIT ;
					 end
		// Cache miss swap out a page
	  	 STORE_PAGE: begin
					if(a_count == PAGE_SIZE+READ_DELAY) nState = LOAD_PREP;
						else nState = STORE_PAGE ;
				  end		
		 LOAD_PREP: begin
				nState = LOAD_PAGE ;
		  end			  
		LOAD_PAGE: begin
						if(a_count == PAGE_SIZE) nState = DATA_IO;
						else nState = LOAD_PAGE ;
					 end
		DATA_WAIT: begin
						nState = DATA_FINISH ;
					 end			 
		DATA_FINISH: begin
						nState = IDLE ;
					 end
	endcase	

end
				 
endmodule