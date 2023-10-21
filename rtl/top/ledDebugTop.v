`ifndef __FILE_LEDDEBUGTOP_V
`define __FILE_LEDDEBUGTOP_V

`include "rtl/components/top.v"
`include "rtl/primitives/synchronizer.v"

module ledDebugTop(
    input sysClk,
    input sysRes,
    output [31:16] PCdebug
);

    wire reset;

    // write data to ram
    initial begin
        `ifdef SPLIT_MEMORY
            $readmemh("firmware/led_text.hex", topInst.instrMemInst, 0, `INSTR_MEM_WORD_CNT-1);
            $readmemh("firmware/led_data.hex", topInst.dataMemInst, 0, `DATA_MEM_WORD_CNT-1);
        `else
            $readmemh("firmware/led.hex", topInst.ramInst.RAM, 0, `RAM_WORD_CNT-1);
        `endif // SPLIT_MEMORY
    end

    // synchronize reset signal
    synchronizer #(
        .LEN(1),
        .STAGES(2)
    ) resetSync (
        .clk(sysClk),
        .dataIn(sysRes),
        .dataOut(reset)
    );

    top topInst(
        .sysClk(sysClk),
        .sysRes(reset)
    );
    
    assign PCdebug = topInst.cpuInst.registerFile32Inst.rf[1][31:16];

endmodule

`endif // __FILE_LEDDEBUGTOP_V
