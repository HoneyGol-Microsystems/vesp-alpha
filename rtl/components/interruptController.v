`ifndef __FILE_INTERRUPTCONTROLLER_V
`define __FILE_INTERRUPTCONTROLLER_V

module interruptController #(
    parameter EXT_IRQ_COUNT = 4
) (
    input               clk,
    input               [EXT_IRQ_COUNT-1:0] irqBus,
    
    output reg          interrupt,
    output reg  [30:0]  intCode
);

    always @(posedge clk) begin

        intCode = 0;

        if (irqBus > 0)
            interrupt = 1;
        else
            interrupt = 0;
    end
    
endmodule

`endif // __FILE_INTERRUPTCONTROLLER_V