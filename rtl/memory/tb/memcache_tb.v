`timescale 1ns/1ps

module memcache_tb;
    localparam integer CLK_HALF = 5;
    localparam integer TIMEOUT_CYCLES = 180;

    reg         clk = 1'b0;
    reg         reset = 1'b0;
    reg         ce = 1'b0;
    reg  [31:0] address = 32'h0;
    reg  [3:0]  be = 4'b1111;
    reg         rw_req = 1'b0;
    reg         rw = 1'b0;
    reg  [31:0] write_data = 32'h0;

    wire [31:0] read_data;
    wire        data_valid;
    wire        busy;
    wire [31:0] sd_address;
    wire        sd_rw_req;
    wire        sd_rw;
    wire [15:0] sd_write_data;
    reg  [15:0] sd_read_data = 16'h0;
    wire [7:0]  sd_burst_len;
    reg         sd_data_bursting = 1'b0;

    reg [15:0] sdram [0:131071];
    integer i;
    integer cycles;
    integer errors = 0;
    integer burst_count = 0;
    reg [31:0] expected_read;

    always #CLK_HALF clk = ~clk;

    memcache dut (
        .clk(clk), .ce(ce), .reset(reset), .address(address), .be(be),
        .rw_req(rw_req), .rw(rw), .write_data(write_data),
        .read_data(read_data), .data_valid(data_valid), .busy(busy),
        .sd_address(sd_address), .sd_rw_req(sd_rw_req), .sd_rw(sd_rw),
        .sd_write_data(sd_write_data), .sd_read_data(sd_read_data),
        .sd_burst_len(sd_burst_len), .sd_data_bursting(sd_data_bursting)
    );

    // The real controller returns one 16-bit word per bursting clock.
    // Keep the model deliberately visible and deterministic in the VCD.
    always @(negedge clk) begin
        sd_data_bursting = sd_rw_req;
        if (sd_rw_req) begin
            if (sd_rw) begin
                sdram[(sd_address >> 1) + burst_count] = sd_write_data;
            end else begin
                sd_read_data = sdram[(sd_address >> 1) + burst_count];
            end
        end else begin
            burst_count = 0;
        end
    end

    always @(posedge clk) begin
        if (sd_rw_req)
            burst_count = burst_count + 1;
    end

    task start_request;
        input [31:0] request_address;
        input        request_rw;
        input [31:0] request_data;
        begin
            @(negedge clk);
            address = request_address;
            rw = request_rw;
            write_data = request_data;
            ce = 1'b1;
            rw_req = 1'b1;
        end
    endtask

    task finish_request;
        begin
            @(negedge clk);
            rw_req = 1'b0;
            ce = 1'b0;
            rw = 1'b0;
        end
    endtask

    task wait_for_valid;
        input [31:0] expected;
        begin
            cycles = 0;
            while (!data_valid && cycles < TIMEOUT_CYCLES) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!data_valid) begin
                $display("TIMEOUT addr=%08h busy=%b state=%0d a_count=%0d sd_req=%b bursts=%0d",
                         address, busy, dut.cState, dut.a_count,
                         sd_rw_req, burst_count);
                errors = errors + 1;
            end else if (read_data !== expected) begin
                $display("FAIL addr=%08h got=%08h expected=%08h state=%0d",
                         address, read_data, expected, dut.cState);
                errors = errors + 1;
            end else begin
                $display("PASS addr=%08h data=%08h cycles=%0d state=%0d",
                         address, read_data, cycles, dut.cState);
            end
            finish_request;
        end
    endtask

    initial begin
        for (i = 0; i < 131072; i = i + 1)
            sdram[i] = 16'h1000 + i[15:0];

        $dumpfile("memcache_tb.vcd");
        $dumpvars(0, memcache_tb);

        repeat (3) @(posedge clk);
        reset = 1'b1;

        // First access is a miss and exercises the complete line-fill path.
        expected_read = {sdram[(32'h0001_0000 >> 1) + 3],
                 sdram[(32'h0001_0000 >> 1) + 2]};
        start_request(32'h0001_0004, 1'b0, 32'h0);
        wait_for_valid(expected_read);

        // A second access to the same line should be a short cache hit.
        start_request(32'h0001_0004, 1'b0, 32'h0);
        wait_for_valid(expected_read);

        // This write is useful for observing byte enables and read-during-write.
        start_request(32'h0001_0004, 1'b1, 32'hdead_beef);
            wait_for_valid(32'h9003_9002);
         start_request(32'h0001_0004, 1'b0, 32'hdead_beef);
      
       
        wait_for_valid(32'hdead_beef);

        if (errors == 0)
            $display("PASS memcache_tb");
        else
            $display("FAIL memcache_tb errors=%0d (inspect memcache_tb.vcd)", errors);
        $finish;
    end

    always @(posedge clk) begin
        if (reset && (dut.cState !== dut.nState))
            $display("TRACE t=%0t state=%0d next=%0d addr=%08h req=%b busy=%b valid=%b sd_req=%b sd_rw=%b burst=%0d",
                     $time, dut.cState, dut.nState, address, rw_req, busy,
                     data_valid, sd_rw_req, sd_rw, burst_count);
    end
endmodule