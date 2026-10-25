



module memcache(input clk,
                  input wire  ce,
                  input reset,
                  input wire [31:0] address,
                  input wire [3:0] be,
                  input wire  rw_req,
                  input wire  rw,
                  input wire[31:0] write_data,
                  output wire[31:0] read_data,
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
               STORE_PAGE = 4'd4 ,
               LOAD_PAGE = 4'd5,
               DATA_FINISH = 4'd6,
               CACHE_CHECK_PRE= 4'd8,
               CACHE_CHECK_PRE2= 4'd9,
               LOAD_PREP=4'd10,
               UPDATE_CL=4'd11;


  // Cache page size
  localparam   PAGE_SIZE=31;  // SDRAM is 16 bit so this is 32 * 16 bit, 16 32 bit words
  // Total chahe row (x2 as 2 associative)
  localparam   CACHE_SIZE=128;


  localparam READ_DELAY=2;
  reg [4:0] nState;
  reg [4:0] cState;

  wire [3:0] cache_offset;
  wire [6:0] cache_set;
  wire [14:0] cache_tag;
  wire [31:0] c_q;
  wire [31:0] c_data;

  reg [15:0] latched;



  wire [10:0]  c_address;
  wire [11:0] cache_data_base;
  wire [11:0] cache_data_base_rl;
  wire [11:0] cache_data_address;
  reg [5:0] a_count;

  wire c_wren;

  wire [3:0]c_be;

  wire [6:0]  cl_address;
  wire cl_wren;
  wire [3:0]cl_be;
  wire [31:0] cl_data[1:0];
  wire [31:0] cl_q[1:0];

  wire cache_hit_set;
  wire cache_hit0;
  wire cache_hit1;

  //  Associative arrays
  //wire acl_wren[1:0];
  //wire [15:0] acl_q[1:0];
  wire ac_wren[1:0];
  wire acc_wren[1:0];
  wire [31:0] ac_q[1:0];


  wire [15:0] h_q[1:0];




  reg [14:0] old_tag;
  reg tag_index;
  reg tag_hit;

  reg replace_index;

  assign sd_burst_len = 8'd31;


  //  Cache Lookup
  assign cache_offset = address[5:2];
  assign cache_set = address[12:6];
  // Reduce total available ram to 1GB as
  // sdram width is 16 and we don't want do 2 reads
  // On systems requiring more than 1GB we would proabaly have a wider dq
  // TODO work out rational behind this......
  assign cache_tag = address[27:13];



  //  Cache access
  assign cache_data_base =  {cache_set,4'b0}; // | tag_index;
  assign cache_data_base_rl =  {cache_set,5'b0}; // | tag_index;
  assign cache_data_address =  cache_data_base+cache_offset;



  assign read_data = c_q ;



  assign cl_address = cache_set; //,1'b0};

  // Update tags on completion


  assign cache_hit0 = (cache_tag == cl_q[0][15:1]);
  assign cache_hit1 = (cache_tag == cl_q[1][15:1]);
  assign cache_hit_set = cache_hit0 ? 1'b0 : 1'b1;

  assign ac_wren[0] = (rw & data_valid & ~cache_hit_set);
  assign ac_wren[1] =  (rw & data_valid & cache_hit_set);

  assign c_q=ac_q[cache_hit_set];

  assign data_valid =(cState == DATA_FINISH) || (cState==CACHE_CHECK && (cache_hit0 || cache_hit1));
  assign busy=(cState  != IDLE);
  //assign c_address = (cState != LOAD_PAGE && cState != STORE_PAGE) ? cache_data_address : cache_data_base+a_count[4:1];
  assign c_address = cache_data_address;
  assign c_data =write_data;

  // Cache refresh

  wire burst = (cState  == LOAD_PAGE) | (cState  == STORE_PAGE);

  assign sd_rw_req= (cState  == LOAD_PAGE) |(cState  == STORE_PAGE);
  assign c_be = (cState != LOAD_PAGE && cState != STORE_PAGE)  ? be : 4'b1111;
  assign sd_address = (cState  == STORE_PAGE) ? {4'h0 ,cl_q[replace_index][15:1],cache_set,6'h0}: {4'h0 ,cache_tag,cache_set,6'h0};
  assign acc_wren[0] = (cState == LOAD_PAGE) & sd_data_bursting & ~replace_index;
  assign acc_wren[1] = (cState == LOAD_PAGE) & sd_data_bursting &  replace_index;
  assign sd_write_data = h_q[replace_index];  //(a_count[0] == 1)  ? ac_q[replace_index][15:0] :  ac_q[replace_index][31:16];
  assign sd_rw = (cState  == STORE_PAGE) ;

  assign cl_data[0]=  ~replace_index ? {cache_tag,1'b1} : {cl_q[0][15:1],1'b0};
  assign cl_data[1]= replace_index ? {cache_tag,1'b1} : {cl_q[1][15:1],1'b0};
  assign cl_wren=( cState  == UPDATE_CL);



  cache_hw cache0(
             .clock(clk),
             .burst(burst),

             .w_address(c_address),
             .w_be(c_be),
             .w_data(c_data),
             .w_wren(ac_wren[0]),
             .w_q(ac_q[0]),

             .h_address( cache_data_base_rl+a_count[4:0]),
             .h_data(sd_read_data),
             .h_wren(acc_wren[0]),
             .h_q(h_q[0])
           );




  cachelookup cachelookup0(.address(cl_address),
                           .clock(clk),
                           .data(cl_data[0]),
                           .wren(cl_wren),
                           .q(cl_q[0]));

  cache_hw cache1(
             .clock(clk),
             .burst(burst),

             .w_address(c_address),
             .w_be(c_be),
             .w_data(c_data),
             .w_wren(ac_wren[1]),
             .w_q(ac_q[1]),

             .h_address( cache_data_base_rl+a_count[4:0]),
             .h_data(sd_read_data),
             .h_wren(acc_wren[1]),
             .h_q(h_q[1])
           );



  cachelookup cachelookup1(.address(cl_address),
                           .clock(clk),
                           .data(cl_data[1]),
                           .wren(cl_wren),
                           .q(cl_q[1]));




  always@(posedge clk)
  begin
    if(~reset)
    begin
      cState <= IDLE;
    end
    else
    begin
      cState <= nState;
    end
  end

  //reg [15:0] latch_sd; // latch the read for cache as it not registered,

  always@(posedge clk)
  begin

    if(cState == CACHE_CHECK)
    begin
      a_count <= -6'd1;;
      if (!cl_q[0][0])
        replace_index <= 1'b0;
      else if (!cl_q[1][0])
        replace_index <= 1'b1;
      else
        replace_index <= 1'b0;
    end
    if(cState ==  LOAD_PREP)
      a_count <=  -6'b1;
    else if(sd_data_bursting && (cState == LOAD_PAGE || cState == STORE_PAGE))
      a_count<=a_count+6'd1;
  end

/*
  reg [15:0] h_q_r [1:0];
  always @(posedge clk) begin
	h_q_r[0] <= h_q[0];
	h_q_r[1] <= h_q[1];
  end
  assign sd_write_data = h_q_r[replace_index];
*/
  always@ ( * )
  begin
    case(cState)
      IDLE:
      begin
        if(rw_req && ce)
          nState = CACHE_CHECK;
        else
          nState = IDLE ;
      end
      REQUEST:
      begin
        nState = CACHE_CHECK ;
      end
      CACHE_CHECK_PRE:
      begin      //  wait cl read
        nState = CACHE_CHECK ;
      end
      CACHE_CHECK:
      begin
        if(cache_hit0 || cache_hit1)
          nState = IDLE;
        //	else if(~cl_q[0][0] || ~cl_q[1][0])	nState = LOAD_PREP;
        else
          nState = STORE_PAGE;
      end

      // Cache miss swap out a page
      STORE_PAGE:
      begin
        if(a_count == PAGE_SIZE+READ_DELAY)
          nState = LOAD_PREP;
        else
          nState = STORE_PAGE ;
      end
      LOAD_PREP:
      begin
        nState = LOAD_PAGE ;
      end
      LOAD_PAGE:
      begin
        if(a_count == PAGE_SIZE)
          nState = UPDATE_CL;
        else
          nState = LOAD_PAGE ;
      end
      UPDATE_CL:
      begin
        nState = REQUEST;
      end

      DATA_FINISH:
      begin
        if(~rw_req  )
          nState = IDLE ;
        else
          nState = DATA_FINISH ;
      end
    endcase

  end

endmodule
