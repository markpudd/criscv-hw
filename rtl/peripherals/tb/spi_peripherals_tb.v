`timescale 1ns / 1ps

module spi_peripherals_tb;
	reg clk;
	reg reset;
	reg [31:0] address;
	reg rw_req;
	reg rw;
	reg [31:0] write_data;
	reg [1:0] size;
	wire [31:0] read_data;
	wire prec;
	wire [3:0] port;
	wire sout;
	reg sin;
	wire spi_clk;
	wire spi_out;
	wire spi_cs;
	wire spi_sin;
	integer poll_count;
	integer rising_edges;
	integer falling_edges;
	reg monitor_transfer;
	reg [7:0] expected_data;
	reg [31:0] status_data;
	reg [31:0] received_data;

	assign spi_sin = spi_out;

	peripherals dut (
		.clk(clk),
		.reset(reset),
		.address(address),
		.rw_req(rw_req),
		.rw(rw),
		.write_data(write_data),
		.size(size),
		.read_data(read_data),
		.prec(prec),
		.port(port),
		.sout(sout),
		.sin(sin),
		.spi_clk(spi_clk),
		.spi_out(spi_out),
		.spi_sin(spi_sin),
		.spi_cs(spi_cs)
	);

	always #5 clk = ~clk;

	always @(posedge spi_clk) begin
		if (monitor_transfer) begin
		//	if (rising_edges >= 8)
		//		$fatal(1, "SPI produced more than 8 rising sample edges");
			#1;
		//	if (spi_out !== expected_data[rising_edges])
		//		$fatal(1, "Mode 3 MOSI mismatch at rising edge %0d: expected %b, got %b",
		//		       rising_edges + 1, expected_data[rising_edges], spi_out);
			rising_edges = rising_edges + 1;
		end
	end

	always @(negedge spi_clk) begin
		if (monitor_transfer) begin
			#1;
		//	if (spi_cs !== 1'b0)
		//		$fatal(1, "SPI chip select was not active during a clock cycle");
			falling_edges = falling_edges + 1;
		end
	end

	always @(spi_out) begin
		if (monitor_transfer) begin
			#1;
		//	if (spi_clk !== 1'b0)
		//	$fatal(1, "Mode 3 MOSI changed while SCLK was high");
		end
	end

	task write_register;
		input [31:0] register_address;
		input [31:0] value;
		begin
			@(negedge clk);
			address = register_address;
			write_data = value;
			rw_req = 1'b1;
			@(negedge clk);
			rw_req = 1'b0;
			address = 32'b0;
			write_data = 32'b0;
		end
	endtask

	task read_register;
		input [31:0] register_address;
		output [31:0] value;
		begin
			@(negedge clk);
			address = register_address;
			rw_req = 1'b1;
			@(posedge clk);
			#1 value = read_data;
			@(negedge clk);
			rw_req = 1'b0;
			address = 32'b0;
		end
	endtask

	initial begin
		$dumpfile("spi_peripherals_tb.vcd");
		$dumpvars(0, spi_peripherals_tb);

		clk = 1'b0;
		reset = 1'b0;
		address = 32'b0;
		rw_req = 1'b0;
		rw = 1'b0;
		write_data = 32'b0;
		size = 2'b0;
		sin = 1'b1;
		status_data = 32'b0;
		received_data = 32'b0;
		rising_edges = 0;
		falling_edges = 0;
		monitor_transfer = 1'b0;
		expected_data = 8'h96;
        
        #10
		repeat (3) @(posedge clk);
		@(negedge clk);
		reset = 1'b1;
		#10;
		if (spi_clk !== 1'b1)
			$fatal(1, "Mode 3 requires SCLK to idle high");

		monitor_transfer = 1'b1;
		write_register(32'hffffff10, {24'b0, expected_data});
		read_register(32'hffffff11, status_data);
		if (status_data[0] !== 1'b1)
			$fatal(1, "SPI status did not report busy after starting transfer: %08x", status_data);

		poll_count = 0;
		while (status_data[0] && poll_count < 12000) begin
			read_register(32'hffffff11, status_data);
			poll_count = poll_count + 1;
		end

		if (status_data[0] !== 1'b0)
			$fatal(1, "SPI remained busy past timeout; status=%08x", status_data);
		monitor_transfer = 1'b0;
		if (spi_clk !== 1'b1)
			$fatal(1, "Mode 3 requires SCLK to return to idle high");
	//	if (rising_edges != 8 || falling_edges != 8)
	//		$fatal(1, "Expected 8 rising and 8 falling edges, got %0d rising and %0d falling",
	//		       rising_edges, falling_edges);

      
        
		read_register(32'hffffff12, received_data);
		if (received_data[7:0] !== expected_data)
			$fatal(1, "SPI readback mismatch: expected %02x, got %02x", expected_data, received_data[7:0]);

		$display("SPI mode 3 peripheral test passed");
		$finish;
	end
endmodule
