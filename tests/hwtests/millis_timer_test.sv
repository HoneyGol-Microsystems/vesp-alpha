`timescale 10ns/1ns

module module_millis_timer_test();

    localparam TIMER_WIDTH   = 32;
    localparam REF_FREQUENCY = 50000000;
    localparam SIM_DIV_VALUE = (REF_FREQUENCY / 1000) - 1;

    int                     sim_divider;

    logic                   reset;
    logic                   clk;
    logic [TIMER_WIDTH-1:0] dout;

    module_millis_timer #(
        .TIMER_WIDTH(TIMER_WIDTH),
        .CLK_FREQ_HZ(REF_FREQUENCY)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .dout(dout)
    );

    // Increment every 1000 cycles.
    timer_incr_check: assert property (
        @(posedge clk) disable iff (reset)
        (sim_divider == SIM_DIV_VALUE) |=> dout == ($past(dout) + 1)
    );

    initial begin

        $display("Millis timer test begin.");
        reset = 1;
        clk   = 0;
        #4;
        reset = 0;
        
        wait(dout == 5);

        $display("Millis timer test finished.");
        $display("ASSERT_SUCCESS");
		#1; $finish;
	end

    // 50 MHz clock
    always begin
        clk = ~clk;
        #1;
    end

    always @(posedge clk) begin
        if (reset || sim_divider == SIM_DIV_VALUE) begin
            sim_divider = 0;
        end else begin
            sim_divider += 1;
        end
    end

endmodule