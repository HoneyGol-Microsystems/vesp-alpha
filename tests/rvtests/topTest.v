`include "src/components/top.v"

module topTest();
    
    reg clk, reset;

    top dut(
        .sys_clk(clk),
        .sys_res(reset)
    );

    initial begin

        $dumpfile("test");
		$dumpvars;

        for (i = 0; i < 38; i++) begin
            reset <= 1;
            $readmemh(__MKPY_CURRENT_TEST, top.ram_main.RAM);
            reset <= 0;

        end

        $finish;
    end

    always begin
		clk <= 1; #1;
        clk <= 0; #1;
	end
    
endmodule