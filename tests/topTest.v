`include "src/components/cpu.v"

module topTest();
    reg clk, reset;
    wire memWr;
    wire [31:0] instr, memOut, PC, memAddr, memIn;
    wire [3:0] wrMask;
    reg [31:0] ram [256:0];

    cpu dut
    (
        .clk(clk),
        .reset(reset),
        .instruction(instr),
        .memReadData(memOut),
        .memWr(memWr),
        .wrMask(wrMask),
        .PC(PC),
        .memAddr(memAddr),
        .memWriteData(memIn)
    );

    initial begin
        $dumpfile("test");
		$dumpvars;

        for (i = 0; i < 38; i++) begin
            reset <= 1;
            $readmemh(hexFiles[i], ram);
            reset <= 0;
            while (1) begin
                // TODO
            end
        end

        $finish;
    end

    always begin
		clk <= 1; #1;
        clk <= 0; #1;
	end


    
endmodule