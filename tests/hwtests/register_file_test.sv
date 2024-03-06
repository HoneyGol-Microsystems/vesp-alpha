`include "rtl/components/register_file32.sv"
`include "rtl/constants.vh"

module register_file_test();
	logic clk, we3;
	logic [4:0] a1, a2, a3;
	logic [31:0] di3, rd1, rd2;

	module_register_file32 #(32) dut
	(
		.a1(a1),
		.a2(a2),
		.a3(a3),
		.di3(di3),
		.we3(we3),
		.clk(clk),
		.rd1(rd1),
		.rd2(rd2)
	);

	initial begin
		a1 = 0;
		a2 = 10;
		a3 = 1;
		di3 = 69;
		we3 = 0;

		#6;
		we3 = 1;
		a1 = a3;

		#10; $display(`ASSERT_SUCCESS); $finish;
	end

	// generate clock
	always begin
		clk <= 1; #1;
        clk <= 0; #1;
	end

endmodule