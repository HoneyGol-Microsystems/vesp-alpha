`include "rtl/components/top.sv"
`include "rtl/constants.vh"

`define __MKPY_CURRENT_TEST "PATH_TO_HEX"
`define OPCODE_PASS         32'b1
`define OPCODE_FAIL         32'b0
`define PC_STOP             'ha4

module top_test();
    
    logic clk, reset;

    module_top dut (
        .clk(clk),
        .reset(reset)
    );

    initial begin

        $readmemh(`__MKPY_CURRENT_TEST, dut.ram.ram, 0, `RAM_WORD_CNT-1);

        reset <= 1;
        
        #2;

        reset <= 0;
        #99999;

        $display(`ASSERT_TIMEOUT);
        $finish;
    end

    always begin
		clk <= 1; #1;
        clk <= 0; #1;
	end

    always_ff @(posedge clk) begin
        if (dut.i_read === `OPCODE_PASS) begin
            $display(`ASSERT_SUCCESS);
            $finish;
        end

        if (dut.i_read === `OPCODE_FAIL) begin
            $display(`ASSERT_FAIL);
            $finish;
        end

        /* stop on certain PC for debugging purposes */
        // if (dut.cpu.pc === `PC_STOP) begin
        //     $display(`ASSERT_DEBUG_STOP);
        //     $finish;
        // end
    end
    
endmodule