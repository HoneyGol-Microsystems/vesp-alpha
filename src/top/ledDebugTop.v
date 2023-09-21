`ifndef __FILE_LEDDEBUGTOP_V
`define __FILE_LEDDEBUGTOP_V

`include "src/components/top.v"
`include "src/primitives/synchronizer.v"

module ledDebugTop(
    input sysClk,
    input sysRes,
    output [31:16] PCdebug
);

    wire reset;
    reg clkdiv2;

    // write data to ram
    initial begin
        `ifdef SPLIT_MEMORY
            $readmemh("asm/led_text.hex", topInst.instrMemInst, 0, `INSTR_MEM_WORD_CNT-1);
            $readmemh("asm/led_data.hex", topInst.dataMemInst, 0, `DATA_MEM_WORD_CNT-1);
        `else
            $readmemh("asm/led.hex", topInst.ramInst.RAM, 0, `RAM_WORD_CNT-1);
        `endif // SPLIT_MEMORY
    end

    synchronizer #(
        .LEN(1),
        .STAGES(2)
    ) resetSync (
        .clk(clkdiv2),
        .dataIn(sysRes),
        .dataOut(reset)
    );    
    
    always @(posedge sysClk) begin
       clkdiv2 <= ~clkdiv2;
    end

    top topInst(
        .sysClk(clkdiv2),
        .sysRes(sysRes)
    );
    
    assign PCdebug = topInst.cpuInst.registerFile32Inst.rf[1][31:16];

endmodule

`endif // __FILE_LEDDEBUGTOP_V
