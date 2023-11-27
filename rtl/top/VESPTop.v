`ifndef __FILE_VESPTOP_V
`define __FILE_VESPTOP_V

`include "rtl/components/top.v"
`include "rtl/primitives/synchronizer.v"

module VESPTop (
    input clk,
    input reset,
    inout [15:0] gpioPorts
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
        .reset(syncReset),
        .gpioPorts(gpioPorts)
    );

endmodule

`endif // __FILE_VESPTOP_V
