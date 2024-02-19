`ifndef __FILE_INTERRUPTCONTROLLER_V
`define __FILE_INTERRUPTCONTROLLER_V

(* dont_touch = "yes" *) module module_interrupt_controller #(
    parameter EXT_IRQ_COUNT = 4
) (
    input  logic                     clk,
    input  logic [EXT_IRQ_COUNT-1:0] irq_bus,
    
    output logic                     interrupt,
    output logic [30:0]              int_code
);

    always_ff @(posedge clk) begin
        int_code <= 0;

        if (irq_bus > 0)
            interrupt <= 1;
        else
            interrupt <= 0;
    end

endmodule

`endif // __FILE_INTERRUPTCONTROLLER_V