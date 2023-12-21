`timescale 1ns/1ns

`define OPCODE_PASS         32'b1
`define OPCODE_FAIL         32'b0
`define PC_STOP             'ha4

module uartTopTest();
    
    reg clk, reset, rx;
    wire tx;
    integer bd_delay = 104167;

    VESPTop dut(
        .clk(clk),
        .reset(reset),
        .tx(tx),
        .rx(rx)
    );

    initial begin
        reset = 1;
        #500;
        reset = 0;
        rx = 1;
        #20;

        // idle
        rx = 1;
        #bd_delay;

        // start bit
        rx = 0;
        #bd_delay;

        // data
        rx = 1;
        #bd_delay;
        rx = 0;
        #bd_delay;
        rx = 1;
        #bd_delay;
        rx = 0;
        #bd_delay;
        rx = 1;
        #bd_delay;
        rx = 0;
        #bd_delay;
        rx = 1;
        #bd_delay;
        rx = 0;
        #bd_delay;

        // stop bit
        rx = 1;
        #bd_delay;

        // idle
        rx = 1;
        #bd_delay;

        // start bit
        rx = 0;
        #bd_delay;

        // data
        rx = 1;
        #bd_delay;
        rx = 1;
        #bd_delay;
        rx = 1;
        #bd_delay;
        rx = 1;
        #bd_delay;
        rx = 0;
        #bd_delay;
        rx = 0;
        #bd_delay;
        rx = 0;
        #bd_delay;
        rx = 0;
        #bd_delay;

        // stop bit
        rx = 1;
        #bd_delay;
    end

    always begin
		clk = 1; #5;
        clk = 0; #5;
	end
    
endmodule