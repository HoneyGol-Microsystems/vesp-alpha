`include "src/components/registerFile32.v"
`include "src/constants.vh"

module registerFileTest();
	reg [4:0] a1, a2, a3;
	reg [31:0] di3;
	reg clk, we3;
	wire [31:0] rd1, rd2;

	registerFile32#(32) dut
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
		$dumpfile("test");
		$dumpvars;

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

	always @ (*) #1 $display ("a1=%b, rd1=%b\na2=%b, rd2=%b\na3=%b, di3=%b, we3=%b, clk=%b\n\n", a1, rd1, a2, rd2, a3, di3, we3, clk);

endmodule