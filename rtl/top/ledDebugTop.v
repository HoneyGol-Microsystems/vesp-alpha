`ifndef __FILE_LEDDEBUGTOP_V
`define __FILE_LEDDEBUGTOP_V

`include "rtl/components/top.v"
`include "rtl/primitives/synchronizer.v"

module ledDebugTop(
    input clk,
    input reset,
    output [31:16] PCdebug
);

    wire syncReset;

    // synchronize reset signal
    synchronizer #(
        .LEN(1),
        .STAGES(2)
    ) resetSync (
        .clk(clk),
        .dataIn(reset),
        .dataOut(syncReset)
    );

    top topInst(
        .clk(clk),
        .reset(syncReset)
    );
    
    assign PCdebug = topInst.cpuInst.registerFile32Inst.rf[1][31:16];

endmodule

`endif // __FILE_LEDDEBUGTOP_V
