`include "rtl/primitives/fifo.sv"
`include "rtl/constants.vh"
`include "tests/test_constants.vh"

module fifo_test();

    logic clk, reset, we, re, empty, full;
    logic  [31:0] din, dout;

    module_fifo #(
        .XLEN  (32),
        .LENGTH(4)
    ) fifo (
        .clk(clk),
        .reset(reset),
        .we(we),
        .re(re),
        .din(din),

        .empty(empty),
        .full(full),
        .dout(dout)        
    );
    
    initial begin

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
        `ASSERT(fifo.front_pointer === 0, "Front pointer did move when empty!");
        `ASSERT(fifo.back_pointer === 0, "Back pointer did move when reading!");

        // Attempt to write.
        re = 0;
        we = 1;
        din = 32'hdeadbeef;
        #2;
        `ASSERT(empty === 0, "Empty != 0 after writing to empty FIFO!");
        `ASSERT(full  === 0, "Full is 1 even when not full!");
        `ASSERT(fifo.front_pointer === 0, "Front pointer did move when writing only!");
        `ASSERT(fifo.back_pointer  === 1, "Back pointer moved wrongly when writing!");

        // Write three more values.
        din = 32'hbababebe;
        #2;
        `ASSERT(fifo.front_pointer === 0, "Front pointer did move when writing only!");
        `ASSERT(fifo.back_pointer  === 2, "Back pointer moved wrongly when writing!");
        `ASSERT(full  === 0, "Full is 1 even when not full!");

        din = 32'hcacacaca;
        #2;
        `ASSERT(fifo.front_pointer === 0, "Front pointer did move when writing only!");
        `ASSERT(fifo.back_pointer  === 3, "Back pointer moved wrongly when writing!");
        `ASSERT(full  === 0, "Full is 1 even when not full!");

        din = 32'hfeedbeef;
        #2;
        `ASSERT(fifo.front_pointer === 0, "Front pointer did move when writing only!");
        `ASSERT(fifo.back_pointer  === 0, "Back pointer moved wrongly when writing!");
        `ASSERT(full  === 1, "Full is 0 even when full!");

        // Attempt to write to full FIFO.
        din = 32'h00000000;
        #2
        `ASSERT(fifo.front_pointer === 0, "Front pointer did move when writing only!");
        `ASSERT(fifo.back_pointer  === 0, "Back pointer moved when writing to full FIFO!");
        `ASSERT(full  === 1, "Full is 0 even when full!");

        // Attempt to read back items in queue.
        re = 1;
        we = 0;
        `ASSERT(dout === 32'hdeadbeef, "Read mismatch.");
        #2;

        `ASSERT(dout === 32'hbababebe, "Read mismatch.");
        #2;

        `ASSERT(dout === 32'hcacacaca, "Read mismatch.");
        #2;

        // Read and write at the same time.
        re = 1;
        we = 1;
        din = 32'h01010101;

        `ASSERT(dout === 32'hfeedbeef, "Read mismatch.");
        #2

        `ASSERT(full  === 0, "Full flag mismatch!");
        `ASSERT(empty === 0, "Empty flag mismatch!");

        // Read last value.
        re = 1;
        we = 0;
        `ASSERT(dout === 32'h01010101, "Read mismatch.")

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