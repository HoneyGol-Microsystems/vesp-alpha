`ifndef __FILE_LEDDEBUGTOP_V
`define __FILE_LEDDEBUGTOP_V

`include "src/components/top.v"

module ledDebugTop(
    input sysClk,
    input sysRes,
    output [31:16] PCdebug
);

    reg clkdiv2;
    
    always @(posedge sysClk) begin
        
        clkdiv2 = ~clkdiv2;
        
        if (sysRes == 1) begin
            clkdiv2 = 0;
        end
    end

    top topInst(
        .sysClk(clkdiv2),
        .sysRes(sysRes)
    );
    
    assign PCdebug = topInst.cpuInst.registerFile32Inst.rf[1][31:16];

endmodule

`endif // __FILE_LEDDEBUGTOP_V