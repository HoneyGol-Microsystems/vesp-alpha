`include "rtl/components/top.v"
`include "rtl/constants.vh"

`define __MKPY_CURRENT_TEST "PATH_TO_HEX"
`define OPCODE_PASS         32'b1
`define OPCODE_FAIL         32'b0
`define PC_STOP             'ha4

module topTest();
    
    reg clk, reset;

    top dut (
        .clk(clk),
        .reset(reset)
    );

    initial begin

        $readmemh(`__MKPY_CURRENT_TEST, dut.ramInst.RAM, 0, `RAM_WORD_CNT-1);

        reset <= 1;
        #1;
        reset <= 0;
        #99999;

        $display(`ASSERT_TIMEOUT);
        $finish;
    end

    always begin
		clk <= 1; #1;
        clk <= 0; #1;
	end

    always @(posedge clk) begin
        if (dut.iRead === `OPCODE_PASS) begin
            $display(`ASSERT_SUCCESS);
            $finish;
        end

        if (dut.iRead === `OPCODE_FAIL) begin
            $display(`ASSERT_FAIL);
            $finish;
        end

        /* stop on certain PC for debugging purposes */
        // if (dut.cpuInst.PC === `PC_STOP) begin
        //     $display(`ASSERT_DEBUG_STOP);
        //     $finish;
        // end
    end
    
endmodule