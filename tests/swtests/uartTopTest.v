`timescale 1ns/1ns

`define OPCODE_PASS         32'b1
`define OPCODE_FAIL         32'b0
`define PC_STOP             'ha4

module uartTopTest();
    
    reg clk, reset;
    wire tx, rx;

    VESPTop dut(
        .clk(clk),
        .reset(reset),
        .tx(tx),
        .rx(rx)
    );

    initial begin
        reset <= 1;
        #500;
        reset <= 0;
    end

    always begin
		clk <= 1; #5;
        clk <= 0; #5;
	end
    
endmodule