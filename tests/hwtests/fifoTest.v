`include "rtl/primitives/fifo.v"
`include "rtl/constants.vh"
`include "tests/testConstants.vh"

module fifoTest();

    reg clk, we, re, reset;
    reg  [31:0] di;
    wire [31:0] do;
    wire empty, full;

    fifo #(
        .XLEN  (32),
        .LENGTH(4)
    ) fifoInst (
        .clk(clk),
        .reset(reset),
        .we(we),
        .re(re),
        .di(di),
        .empty(empty),
        .full(full),
        .do(do)        
    );
    
    initial begin
		// $dumpfile("test");
		// $dumpvars;

        clk   = 0;
        we    = 0;
        re    = 0;
        reset = 1;
        $display("FIFO test begin");
        
        // Wait one clock cycle to reset.
        #2;
        reset = 0;

        // Check after-reset values.
        `ASSERT(empty === 1, "Empty != 1 after reset!");
        `ASSERT(full  === 0, "Full != 0 after reset!");

        // Attempt to read - frontPointer should not move.
        re = 1;
        #2;
        `ASSERT(empty === 1, "Empty != 1 after reading empty FIFO!");
        `ASSERT(fifoInst.frontPointer === 0, "Front pointer did move when empty!");
        `ASSERT(fifoInst.backPointer === 0, "Back pointer did move when reading!");

        // Attempt to write.
        re = 0;
        we = 1;
        di = 32'hdeadbeef;
        #2;
        `ASSERT(empty === 0, "Empty != 0 after writing to empty FIFO!");
        `ASSERT(full  === 0, "Full is 1 even when not full!");
        `ASSERT(fifoInst.frontPointer === 0, "Front pointer did move when writing only!");
        `ASSERT(fifoInst.backPointer  === 1, "Back pointer moved wrongly when writing!");

        // Write three more values.
        di = 32'hbababebe;
        #2;
        `ASSERT(fifoInst.frontPointer === 0, "Front pointer did move when writing only!");
        `ASSERT(fifoInst.backPointer  === 2, "Back pointer moved wrongly when writing!");
        `ASSERT(full  === 0, "Full is 1 even when not full!");

        di = 32'hcacacaca;
        #2;
        `ASSERT(fifoInst.frontPointer === 0, "Front pointer did move when writing only!");
        `ASSERT(fifoInst.backPointer  === 3, "Back pointer moved wrongly when writing!");
        `ASSERT(full  === 0, "Full is 1 even when not full!");

        di = 32'hfeedbeef;
        #2;
        `ASSERT(fifoInst.frontPointer === 0, "Front pointer did move when writing only!");
        `ASSERT(fifoInst.backPointer  === 0, "Back pointer moved wrongly when writing!");
        `ASSERT(full  === 1, "Full is 0 even when full!");

        // Attempt to write to full FIFO.
        di = 32'h00000000;
        #2
        `ASSERT(fifoInst.frontPointer === 0, "Front pointer did move when writing only!");
        `ASSERT(fifoInst.backPointer  === 0, "Back pointer moved when writing to full FIFO!");
        `ASSERT(full  === 1, "Full is 0 even when full!");

        // Attempt to read back items in queue.
        re = 1;
        we = 0;
        `ASSERT(do === 32'hdeadbeef, "Read mismatch.");
        #2;

        `ASSERT(do === 32'hbababebe, "Read mismatch.");
        #2;

        `ASSERT(do === 32'hcacacaca, "Read mismatch.");
        #2;

        // Read and write at the same time.
        re = 1;
        we = 1;
        di = 32'h01010101;

        `ASSERT(do === 32'hfeedbeef, "Read mismatch.");
        #2

        `ASSERT(full  === 0, "Full flag mismatch!");
        `ASSERT(empty === 0, "Empty flag mismatch!");

        // Read last value.
        re = 1;
        we = 0;
        `ASSERT(do === 32'h01010101, "Read mismatch.")

        #2
        `ASSERT(full  === 0, "Full flag mismatch!");
        `ASSERT(empty === 1, "Empty flag mismatch!");

		$display(`ASSERT_SUCCESS); $finish;
	end

    always begin
        clk = ~clk;
        #1;
    end

endmodule