module counter_test();

    localparam COUNTER_WIDTH = 4;
    localparam TB_WAIT       = 200;

    logic reset;
    logic clk;
    logic en;
    logic [COUNTER_WIDTH-1:0] max;
    logic top;
    logic top_pulse;
    logic [COUNTER_WIDTH-1:0] val;

    module_counter #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) DUT (
        .reset(reset),
        .clk(clk),
        .en(en),
        .max(max),

        .top(top),
        .top_pulse(top_pulse),
        .val(val)
    );

    // If the value equals max, the top is high.
    top_check: assert property (@(posedge clk)  top   |-> (val == max));

    // After top rises, top_pulse rises as well.
    // Note: $rise is necessary here, otherwise it'll check that top_pulse is high
    // everytime the top is high.
    top_pulse_valid_check: assert property (@(posedge clk) $rose(top) |-> $rose(top_pulse));

    // Top pulse is high only for 1 cycle.   
    top_pulse_len_check: assert property (@(posedge clk) top_pulse == 1 |=> top_pulse == 0);

    // Value is always incremented (when not reset).
    incr_check: assert property (
        @(posedge clk) disable iff (reset)
        en |-> (val == ($past(val) + 1))
    );

    // Value after reaching max is 0 again on next enable.
    max_reset_check: assert property (
        @(posedge en)
        top |=> (val == 0)
    );

    initial begin

        $display("Counter test begin.");
        en  = 0;
        clk = 0;
        max = 7;
        reset = 1;
        #8;
        
        reset = 0;
        assert(val == 0) else $fatal("Initial value mismatch.");

        #(TB_WAIT);

        $display("Counter test finished.");
        $display("ASSERT_SUCCESS");
		#1; $finish;
	end

    always begin
        clk = ~clk;
        #1;
    end

    // Enable is 2 times slower than clk.
    // Also it is only a pulse.
    always begin
        en = 1;
        #1;
        en = 0;
        #3;
    end

endmodule