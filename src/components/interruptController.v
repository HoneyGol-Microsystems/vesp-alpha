`ifndef __FILE_INTERRUPTCONTROLLER_V
`define __FILE_INTERRUPTCONTROLLER_V

module interruptController # (
    parameter EXT_IRQ_COUNT = 4
) (
    input       clk,
    input       [EXT_IRQ_COUNT-1:0] extIrq,
    output reg  interrupt
);

    always @(posedge clk) begin
        if (extIrq > 0)
            interrupt = 1;
        else
            interrupt = 0;
    end
    
endmodule

`endif // __FILE_INTERRUPTCONTROLLER_V