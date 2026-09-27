// Self-checking integration bench for mmu -> memcache -> sdramburst.
// The ISSI model is connected as the external SDRAM device.
`timescale 1ns/1ps

module tb_mmu_sdram;
    localparam integer CLK_HALF = 5;
    localparam integer MCLK_HALF = 2;
    localparam integer INIT_TIMEOUT = 200000;
    localparam integer OP_TIMEOUT = 20000;
    localparam [1:0] SZ_WORD = 2'd2;

    reg clk = 1'b0;
    reg mclk = 1'b0;
    reg reset = 1'b0;
    reg [31:0] address = 32'h0;
    reg rw = 1'b0;
    reg [31:0] write_data = 32'h0;
    reg [1:0] size = SZ_WORD;
    reg m_valid = 1'b0;

    wire [31:0] read_data;
    wire s_valid;
    wire sd_ce;
    wire [31:0] sd_address;
    wire sd_rw_req;
    wire sd_rw;
    wire [15:0] sd_write_data;
    wire [7:0] sd_burst_len;
    wire [15:0] sd_read_data;
    wire sd_data_bursting;

    wire [15:0] dram_dq;
    wire [12:0] dram_addr;
    wire [1:0] dram_dqm;
    wire dram_cke, dram_we_n, dram_cas_n, dram_ras_n, dram_cs_n;
    wire dram_ba0, dram_ba1;
    wire dram_init_done;

    integer checks = 0;
    integer errors = 0;
    integer cycles;
    reg [31:0] result;

    always #CLK_HALF clk = ~clk;
    always #MCLK_HALF mclk = ~mclk;

    mmu dut (
        .clk(clk), .mclk(mclk), .reset(reset),
        .address(address), .rw(rw), .write_data(write_data), .size(size),
        .read_data(read_data), .m_valid(m_valid), .s_valid(s_valid),
        .sd_ce(sd_ce), .sd_address(sd_address), .sd_rw_req(sd_rw_req),
        .sd_rw(sd_rw), .sd_write_data(sd_write_data),
        .sd_burst_len(sd_burst_len), .sd_read_data(sd_read_data),
        .sd_data_bursting(sd_data_bursting)
    );

    sdramburst memory_controller (
        .clk(mclk), .ce(sd_ce), .reset(reset), .address(sd_address),
        .rw_req(sd_rw_req), .rw(sd_rw), .write_data(sd_write_data),
        .read_data(sd_read_data), .burst_len(sd_burst_len),
        .data_bursting(sd_data_bursting), .dclk(mclk), .dram_dq(dram_dq),
        .dram_addr(dram_addr), .dram_dqm(dram_dqm), .dram_cke(dram_cke),
        .dram_we_n(dram_we_n), .dram_cas_n(dram_cas_n),
        .dram_ras_n(dram_ras_n), .dram_cs_n(dram_cs_n),
        .dram_ba0(dram_ba0), .dram_ba1(dram_ba1),
        .init_done(dram_init_done)
    );

    IS42VM16400K dram (
        .dq(dram_dq), .addr(dram_addr), .ba({dram_ba0, dram_ba1}),
        .clk(mclk), .cke(dram_cke), .csb(dram_cs_n), .rasb(dram_ras_n),
        .casb(dram_cas_n), .web(dram_we_n), .dqm(dram_dqm)
    );

    task check;
        input [8*48:1] name;
        input [31:0] got;
        input [31:0] expected;
        begin
            checks = checks + 1;
            if (got !== expected) begin
                errors = errors + 1;
                $display("FAIL %0s got=%08h expected=%08h t=%0t", name, got, expected, $time);
            end else begin
                $display("PASS %0s = %08h", name, got);
            end
        end
    endtask

    task wait_for_init;
        begin
            cycles = 0;
            while (!dram_init_done && cycles < INIT_TIMEOUT) begin
                @(posedge mclk);
                cycles = cycles + 1;
            end
            if (!dram_init_done) begin
                $display("FAIL SDRAM initialization timeout");
                errors = errors + 1;
                $finish;
            end
            $display("SDRAM initialized after %0d mclk cycles", cycles);
        end
    endtask

    task bus_op;
        input [31:0] a;
        input is_write;
        input [31:0] wd;
        output [31:0] rd;
        begin
            @(negedge clk);
            address = a;
            rw = is_write;
            write_data = wd;
            m_valid = 1'b1;
            cycles = 0;
            while (!s_valid && cycles < OP_TIMEOUT) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!s_valid) begin
                $display("FAIL transaction timeout addr=%08h write=%b", a, is_write);
                errors = errors + 1;
            end
            rd = read_data;
            @(negedge clk);
            m_valid = 1'b0;
            rw = 1'b0;
        end
    endtask

    task write_word;
        input [31:0] a;
        input [31:0] d;
        begin
            bus_op(a, 1'b1, d, result);
        end
    endtask

    task read_word;
        input [31:0] a;
        output [31:0] d;
        begin
            bus_op(a, 1'b0, 32'h0, d);
        end
    endtask

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("mmu_sdram_tb.vcd");
            $dumpvars(0, tb_mmu_sdram);
        end

        repeat (4) @(posedge clk);
        reset = 1'b1;
        wait_for_init;

        write_word(32'h0001_0040, 32'h1234_5678);
        read_word (32'h0001_0040, result);
        check("cached word", result, 32'h1234_5678);
        read_word (32'h0001_0040, result);
        check("cache hit", result, 32'h1234_5678);

        write_word(32'h0001_0121, 32'h89ab_cdef);
        read_word (32'h0001_0121, result);
        check("odd cached word", result, 32'h89ab_cdef);

        if (errors == 0)
            $display("PASS mmu_sdram checks=%0d", checks);
        else begin
            $display("FAIL mmu_sdram checks=%0d errors=%0d", checks, errors);
            $fatal(1);
        end
        $finish;
    end
endmodule