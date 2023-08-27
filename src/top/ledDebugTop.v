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

    synchronizer #(
        .LEN(1),
        .STAGES(2)
    ) resetSync (
        .clk(clkdiv2),
        .dataIn(sysRes),
        .dataOut(reset)
    );    
    
    always @(posedge sysClk) begin
       clkdiv2 = ~clkdiv2;
    end

    top topInst(
        .sysClk(clkdiv2),
        .sysRes(sysRes)
    );
    
    assign PCdebug = topInst.cpuInst.registerFile32Inst.rf[1][31:16];

endmodule

`endif // __FILE_LEDDEBUGTOP_V