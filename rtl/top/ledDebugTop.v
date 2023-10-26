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
