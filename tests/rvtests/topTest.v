`include "src/components/top.v"

module topTest();
    
    reg clk, reset;

    top dut(
        .sysClk(clk),
        .sysRes(reset)
    );

    initial begin

        $dumpfile("test");
		$dumpvars;
        $readmemh(__MKPY_CURRENT_TEST, dut.ram_main.RAM);

        reset <= 1;
        #1;
        reset <= 0;

        $finish;
    end

    always begin
		clk <= 1; #1;
        clk <= 0; #1;
	end
    
endmodule