(* dont_touch = "yes" *) module module_counter #(
    parameter COUNTER_WIDTH = 4
) (
    input  logic                     reset,
    input  logic                     clk,
    input  logic                     en,
    input  logic [COUNTER_WIDTH-1:0] max,

    output logic                     top,
    output logic                     top_pulse,
    output logic [COUNTER_WIDTH-1:0] val
);

    logic [COUNTER_WIDTH-1:0] counter;
    logic top_processed;

    assign val       = counter;
    assign top       = (counter == max);
    assign top_pulse = top && !top_processed;

    always_ff @(posedge clk) begin : counter_proc
        if (reset)
            counter <= 0;
        else if (en) begin
            if (top)
                counter <= 0;
            else
                counter <= counter + 1;
        end
    end

    always_ff @(posedge clk) begin : top_proc
        if (reset) begin
            top_processed <= 0;
        end else begin
            if (top) begin
                if (!top_processed) begin
                    top_processed <= 1;
                end
            end else begin
                top_processed <= 0;
            end
        end
    end

endmodule