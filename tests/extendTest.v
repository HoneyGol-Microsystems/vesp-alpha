`include "../src/components/extend.v"

module extendTest();
	reg [7:0] data8;
    reg [15:0] data16;
    reg uext, clk;
    wire [31:0] res8, res16;

	extend#(8, 32) ext8_32(data8, uext, res8);
    extend#(16, 32) ext16_32(data16, uext, res16);

	initial begin
		$dumpfile("test");
		$dumpvars;

        #2;
        data8 = 8'b00001111;
        data16 = data8;
        uext = 1;

		#2;
        data8 = 8'b00001111;
        data16 = data8;
        uext = 0;

        #2;
        data8 = 8'b10001111;
        data16 = { data8[7:4], 8'b0, data8[3:0] };
        uext = 1;

        #2;
        data8 = 8'b10001111;
        data16 = { data8[7:4], 8'b0, data8[3:0] };
        uext = 0;

		#1; $finish;
	end

	// generate clock
	always begin
		clk <= 1; #1;
        clk <= 0; #1;
	end

	always @ (*) #1 $display ("data8=%b, uext=%b, res8=%b\ndata16=%b, uext=%b, res16=%b\n", data8, uext, res8, data16, uext, res16);

endmodule