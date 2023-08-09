`include "src/components/top.v"
`include "src/constants.vh"

`define __MKPY_CURRENT_TEST "PATH_TO_HEX"
`define ECALL               32'b1110011
`define EBREAK              32'b100000000000001110011

module topTest();
    
    reg clk, reset;
    integer i;

    top dut(
        .sysClk(clk),
        .sysRes(reset)
    );

    initial begin

        $dumpfile("test");
		$dumpvars;
        $readmemh(`__MKPY_CURRENT_TEST, dut.ramMain.RAM);

        reset <= 1;
        #1;
        reset <= 0;
        #99999;

        $display("TIMEOUT");
        $finish;
    end

    always begin
		clk <= 1; #1;
        clk <= 0; #1;
	end

    always @(posedge clk) begin
        if (dut.instrBusData == `ECALL) begin
            $display(`ASSERT_SUCCESS);
            $finish;
        end

        if (dut.instrBusData == `EBREAK) begin
            $display(`ASSERT_FAIL);
            $finish;
        end

        // if (dut.cpu.PC == 'h88) begin
        //     $display("DEBUG_STOP");
        //     $finish;
        // end
    end
    
endmodule