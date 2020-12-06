module memcache(input clk,
				input mclk,
				input wire  ce,
			   input reset,
				input wire [31:0] address,
				input wire [1:0] be,
				input wire  rw_req,
				input wire  rw,
				input wire[15:0] write_data,
				output wire[15:0] read_data,
				output data_valid,
				output busy,
						 

				output wire	[31:0]  sd_address,
				output wire sd_rw_req,
				output wire  sd_rw,
				output wire[15:0] sd_write_data,
				input wire[15:0] sd_read_data,
				output wire[7:0] sd_burst_len,
				input wire sd_data_bursting);
						 
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
				 LOAD_PREP=4'd10,
				 UPDATE_CL=4'd11;
				 
				 
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
wire [15:0] c_data;





wire [11:0]  c_address;
wire [11:0] cache_data_base;
wire [11:0] cache_data_address;
reg [5:0] a_count;

wire c_wren;

wire [1:0]c_be;

wire [6:0]  cl_address;
wire cl_wren;
wire [1:0]cl_be;
wire [15:0] cl_data[1:0];
wire [15:0] cl_q[1:0];

wire cache_hit_set;

//  Associative arrays
//wire acl_wren[1:0];
//wire [15:0] acl_q[1:0];
wire ac_wren[1:0];
wire [15:0] ac_q[1:0];



wire fsm_clk;

reg [14:0] old_tag;
reg tag_index;
reg tag_hit;

reg replace_index;

assign sd_burst_len = 8'd31;

assign cache_offset = address[5:1];
assign cache_set = address[12:6];
assign cache_data_base =  {cache_set,5'b0}; // | tag_index;
assign cache_data_address =  cache_data_base+cache_offset;

// Reduce total available ram to 1GB as
// sdram width is 16 and we don't want do 2 reads
// On systems requiring more than 1GB we would proabaly have a wider dq
assign cache_tag = address[27:13];
assign sd_address = (cState  == STORE_PAGE) ? {4'h0 ,cl_q[replace_index][15:1],cache_set,6'h0}: {4'h0 ,cache_tag,cache_set,6'h0};

assign read_data = c_q ;						  
assign sd_write_data = ac_q[replace_index];
assign sd_rw = (cState  == STORE_PAGE) ;
assign sd_rw_req= (cState  == LOAD_PAGE) |(cState  == STORE_PAGE);

assign c_address = (cState != LOAD_PAGE && cState != STORE_PAGE) ? cache_data_address : cache_data_base+a_count[4:0];
assign c_data =(cState != LOAD_PAGE && cState != STORE_PAGE) ?  write_data :sd_read_data;
//assign c_wren = (cState  == LOAD_PAGE) | (rw && (cState == DATA_FINISH));
assign c_be = (cState != LOAD_PAGE && cState != STORE_PAGE)  ? be : 2'b11;


assign cl_address = cache_set; //,1'b0};

// Update tags om completion
assign cl_data[0]=  ~replace_index ? {cache_tag,1'b1} : {cl_q[0][15:1],1'b0};
assign cl_data[1]= replace_index ? {cache_tag,1'b1} : {cl_q[1][15:1],1'b0};
assign cl_wren=( cState  == UPDATE_CL);

assign cache_hit_set = (cache_tag == cl_q[0][15:1]) ? 1'b0 : 1'b1;

assign ac_wren[0] =  (cState  == LOAD_PAGE & ~replace_index ) | (rw & (cState == DATA_FINISH) & ~cache_hit_set); 
assign ac_wren[1] = (cState  == LOAD_PAGE & replace_index ) | (rw & (cState == DATA_FINISH) & cache_hit_set); 


assign c_q=ac_q[cache_hit_set];



assign data_valid = (cState == DATA_FINISH);
assign busy=(cState  != IDLE);

// Slow clock for sdram
assign fsm_clk =  (cState == IDLE ||
						cState == REQUEST ||
						cState == CACHE_CHECK ||	
						cState == DATA_WAIT ||
						cState == DATA_FINISH ||
						cState ==  DATA_IO) ? clk : mclk;

// Cache set 0						
cache cache0(.address(c_address),
						.byteena(c_be),
						.clock(fsm_clk),
						.data(c_data),
						.wren(ac_wren[0]),
						.q(ac_q[0]));

cachelookup cachelookup0(.address(cl_address),
						.clock(fsm_clk),
						.data(cl_data[0]),
						.wren(cl_wren),
						.q(cl_q[0]));


// Cache set 1						
cache cache1(.address(c_address),
						.byteena(c_be),
						.clock(fsm_clk),
						.data(c_data),
						.wren(ac_wren[1]),
						.q(ac_q[1]));

cachelookup cachelookup1(.address(cl_address),
						.clock(fsm_clk),
						.data(cl_data[1]),
						.wren(cl_wren),
						.q(cl_q[1]));


					
					
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
	if(cState == CACHE_CHECK) 
	begin
		a_count =0;
		replace_index = cl_q[0][0];
	end
	if(cState ==  LOAD_PREP) a_count =-6'b1;
	else if(sd_data_bursting && (cState == LOAD_PAGE || cState == STORE_PAGE))
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
					if(cache_tag == cl_q[0][15:1] || cache_tag == cl_q[1][15:1])	nState = DATA_FINISH;
		//			else if(cl_q[0][15:1] == 0  || cl_q[1][15:1] == 0)	nState = DATA_FINISH;
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
						if(a_count == PAGE_SIZE) nState = UPDATE_CL;
						else nState = LOAD_PAGE ;
					 end
		 UPDATE_CL: begin
				nState = REQUEST; 
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