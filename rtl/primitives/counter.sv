
(* dont_touch = "yes" *) module counter #(
    parameter COUNTER_WIDTH = 4
) (
    input  logic                     reset,
    input  logic                     clk,
    input  logic                     en,
    input  logic [COUNTER_WIDTH-1:0] max,
    output logic                     top,
    output logic [COUNTER_WIDTH-1:0] val
);

    logic [COUNTER_WIDTH-1:0] counter;
    assign val = counter;

    always_ff @(posedge clk) begin : counter_proc
        if (reset)
            counter <= 0;
        else if (en)
            counter <= counter + 1;
    end
    assign top = (counter == max);

endmodule