(* dont_touch = "yes" *) module millis_timer #(
    TIMER_WIDTH = 32,
    CLK_FREQ_HZ = 50000000
) (
    input  logic                   clk,
    input  logic                   reset,
    output logic [TIMER_WIDTH-1:0] dout
);

    localparam CLK_DIV_MAX = CLK_FREQ_HZ / 1000;
    
    logic [31:0] counter_value;
    logic        millis_en;

    counter #(
        .COUNTER_WIDTH($clog2(CLK_DIV_MAX))
    ) clk_divider (
        .reset(reset),
        .clk(clk),
        .en(1),
        .max(CLK_DIV_MAX - 1),
        .top_pulse(millis_en)
    );

    counter #(
        .COUNTER_WIDTH(TIMER_WIDTH)
    ) millis_counter (
        .reset(reset),
        .clk(clk),
        .en(millis_en),
        .max(32'hFFFFFFFF),
        .val(counter_value)
    );
    
    assign dout = counter_value;

    generate
        if ( CLK_FREQ_HZ < 1000 ) $fatal("Clock frequency is too low!");
    endgenerate
    
endmodule