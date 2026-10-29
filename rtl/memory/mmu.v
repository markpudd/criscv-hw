/*  Super simple  MMU,  there is massive optimzations that could be done for this:-
			*  Bigger reads - Currently using 16-bit memory - the built in Cyclone memory can deliver 256 bits at a time
			*  Use Cyclone dual port to optimizes instruction vs data
			*  Add pre-fetch (likely next read is last read (pc) +4
*/
module mmu(input clk,
				 input reset,
				 


				     // Instruction Path Interface
				input wire [31:0] inst_addr,
				output reg [31:0] inst_out,
				input wire        inst_m_valid,  // master valid
				output            inst_s_valid,

				// Data Path Interface
				input wire [31:0] data_addr,
				input wire [31:0] data_in,
				input wire        data_we,       // Write enable for data path
				output reg [31:0] data_out,
				input wire[1:0]   data_size,
				input wire        data_m_valid,  // master valid
				output            data_s_valid,

/*				 input wire [31:0] address,
				 input wire  rw,
				 input wire[31:0] write_data,
				 input wire[1:0] size,
				 output wire[31:0] read_data,
				 
				 input wire       m_valid,  // master valid
				 output          s_valid,  // slave valid*/
				 
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

	reg [31:0] mem_address;
	reg [1:0]  mem_size;
	reg        mem_rw;
	reg [31:0] mem_write_data;
	reg        m_valid;

	wire [31:0] read_data;
	wire        s_valid;
				 

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

	/*ram ram(.address(ram_address),
				.byteena(be),
				.clock(clk),
				.data(br_data),
				.wren(br_lwren),
				.q(lbr_q));*/
	
	//* 
	//  This is a more portable version which I'm still working on

		iram #(
		.ADDR_W   (LOW_RAM_WIDTH+1),   // 14 — matches ram_address[LOW_RAM_WIDTH:0]
		.DEPTH_W  (12),                // 4K words = 16KB; match the old numwords_a
		.NB_COL   (4),                 // 4 byte lanes ...
		.COL_W    (8),                 // ... of 8 bits = 32-bit word
		.INIT_FILE("/mnt/fpga/criscv-hw/bootloader/boot.hex")         // whatever init_file the megafunction used
	) lowram (
		.address (ram_address),
		.byteena (be),
		.clock   (clk),
		.data    (br_data),
		.wren    (br_lwren),
		.q       (lbr_q)
	);
	//*/
assign br_q = ce ?	hbr_q : lbr_q;

assign br_hwren = br_wren && ce;
assign br_lwren = br_wren && cel;
assign br_address =  mem_address;
assign ram_address = br_address[LOW_RAM_WIDTH+1:2];
assign ce = (mem_address[31]==0  && mem_address >= 32'h10000);
assign cel = (mem_address[31]==0  && mem_address < 32'h10000);
	
	

						  
						  
assign mem_req = (m_valid && ce );
assign br_wren = 	(m_valid && mem_rw );

assign s_valid = (ce ? mc_data_valid : lm_v );//& m_valid;




assign be_mask = (mem_size == 0) ? 4'b0001 : 
					  (mem_size == 1) ? 4'b0011 :
					                4'b1111;
//
/*
 *  These can be reduced but for ease of readabilty keep them full for now
 */
assign be = 	be_mask << mem_address[1:0];
					  
assign br_data =  (mem_size ==0) ? {4{mem_write_data[7:0]}} :
						(mem_size == 1) ? {2{mem_write_data[15:0]}} :
						mem_write_data;
						
						
assign read_data  = br_q >> {mem_address[1:0], 3'b000};

/*
always @(*)
begin
if(owner_d)
data_out = read_data;
else
	inst_out = read_data;	
end
*/

always @(*) begin
	data_out = read_data;
	inst_out = read_data;
end

parameter RAM_DELAY =3'b0;

//---------------------------------------------------------------------------
  // Mem Arb --  AI generated this arb originally and TBH it sucks.......
  //---------------------------------------------------------------------------

  reg         busy;              // an access is outstanding
  reg         owner_d;           // 1 = D-side owns the outstanding access

  wire        pick_d = data_m_valid;    // D priority
  wire        s_valid_i = s_valid & busy & ~owner_d;
  wire        s_valid_d = s_valid & busy &  owner_d;

  assign inst_s_valid = s_valid_i;
  assign data_s_valid = s_valid_d;

  always @(posedge clk)
  begin
    if (~reset)
    begin
      busy       <= 1'b0;
      owner_d    <= 1'b0;
      m_valid    <= 1'b0;
      mem_address <= 32'b0;
      mem_size    <= 2'b0;
      mem_rw      <= 1'b0;
      mem_write_data <= 32'b0;
    end
    else if (!busy)
    begin
      if (inst_m_valid || data_m_valid)
      begin
        busy            <= 1'b1;
        owner_d         <= pick_d;
        mem_address     <= pick_d ? {20'b0, data_addr} : {20'b0, inst_addr};
        mem_size        <= pick_d ? data_size : 2'b10;
        mem_rw          <= pick_d ? data_we : 1'b0;
        mem_write_data  <= data_in;
        m_valid         <= 1'b1;
      end
    end
    else if (s_valid)
    begin
      // A completion consumes the current owner's request. If the other
      // requester is waiting, switch directly to it without dropping m_valid.
      if (owner_d ? inst_m_valid : data_m_valid)
      begin
        owner_d         <= ~owner_d;
        mem_address     <= owner_d ? {20'b0, inst_addr} : {20'b0, data_addr};
        mem_size        <= owner_d ? 2'b10 : data_size;
        mem_rw          <= owner_d ? 1'b0 : data_we;
        mem_write_data  <= data_in;
        m_valid         <= 1'b1;
      end
      else
      begin
        busy    <= 1'b0;
        m_valid <= 1'b0;
      end
    end
  end



	
always@ ( posedge clk) begin
  if(~reset)
  begin
	  mdelay <= RAM_DELAY;
	  lm_v <=0;
	end
	else if(lm_v) begin
		// completion consumed this cycle
		lm_v   <= 0;
		mdelay <= RAM_DELAY;
	end
	else if(m_valid && !ce) begin
		if(mdelay == 0)
			lm_v <= 1;
		else
			mdelay <= mdelay - 3'b1;
	end else
	begin
		mdelay <= RAM_DELAY;
		lm_v <=0;
	end
end
	
	

endmodule