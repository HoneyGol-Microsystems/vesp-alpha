`include "src/components/cpu.v"

module topTest();
    reg clk, reset, memWr;
    wire [31:0] instr, memOut, PC, memAddr, memIn;
    wire [3:0] wrMask;
    reg [31:0] ram [256:0];
    localparam reg [100:0] hexFiles[37:0] = '{
        "../hex/rv32ui-p-simple.hex",
        "../hex/rv32ui-p-add.hex",
        "../hex/rv32ui-p-addi.hex",
        "../hex/rv32ui-p-and.hex",
        "../hex/rv32ui-p-andi.hex",
        "../hex/rv32ui-p-auipc.hex",
        "../hex/rv32ui-p-beq.hex",
        "../hex/rv32ui-p-bge.hex",
        "../hex/rv32ui-p-bgeu.hex",
        "../hex/rv32ui-p-blt.hex",
        "../hex/rv32ui-p-bltu.hex",
        "../hex/rv32ui-p-bne.hex",
        "../hex/rv32ui-p-jal.hex",
        "../hex/rv32ui-p-jalr.hex",
        "../hex/rv32ui-p-lb.hex",
        "../hex/rv32ui-p-lbu.hex",
        "../hex/rv32ui-p-lh.hex",
        "../hex/rv32ui-p-lhu.hex",
        "../hex/rv32ui-p-lui.hex",
        "../hex/rv32ui-p-lw.hex",
        "../hex/rv32ui-p-or.hex",
        "../hex/rv32ui-p-ori.hex",
        "../hex/rv32ui-p-sb.hex",
        "../hex/rv32ui-p-sh.hex",
        "../hex/rv32ui-p-sll.hex",
        "../hex/rv32ui-p-slli.hex",
        "../hex/rv32ui-p-slt.hex",
        "../hex/rv32ui-p-slti.hex",
        "../hex/rv32ui-p-sltiu.hex",
        "../hex/rv32ui-p-sltu.hex",
        "../hex/rv32ui-p-sra.hex",
        "../hex/rv32ui-p-srai.hex",
        "../hex/rv32ui-p-srl.hex",
        "../hex/rv32ui-p-srli.hex",
        "../hex/rv32ui-p-sub.hex",
        "../hex/rv32ui-p-sw.hex",
        "../hex/rv32ui-p-xor.hex",
        "../hex/rv32ui-p-xori.hex"
    };

    cpu dut
    (
        .clk(clk),
        .reset(reset),
        .instr(instruction),
        .memOut(memOut),
        .memWr(memWr),
        .wrMask(wrMask),
        .PC(PC),
        .memAddr(memAddr),
        .memIn(memIn)
    );

    initial begin
        $dumpfile("test");
		$dumpvars;

        for (i = 0; i < 38; i++) begin
            reset <= 1;
            $readmemh(hexFiles[i], ram);
            reset <= 0;
            while () begin
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