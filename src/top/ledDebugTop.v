`ifndef __FILE_LEDDEBUGTOP_V
`define __FILE_LEDDEBUGTOP_V

`include "src/components/top.v"

module ledDebugTop(
    input sysClk,
    input sysRes,
    output [31:16] PCdebug
);

    top topInst(
        .sysClk(sysClk),
        .sysRes(sysRes)
    );
    
    assign PCdebug = topInst.cpuInst.PC[31:16];

endmodule

`endif // __FILE_LEDDEBUGTOP_V