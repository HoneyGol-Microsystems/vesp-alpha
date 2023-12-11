`ifndef __FILE_VESPTOP_V
`define __FILE_VESPTOP_V

(* dont_touch = "yes" *) module VESPTop (
    input clk,
    input reset,
    inout [15:0] gpioPorts
);

    wire syncReset, pllFeedback, divClk;

    // synchronize reset signal
    synchronizer #(
        .LEN(1),
        .STAGES(2)
    ) resetSync (
        .clk(divClk),
        .dataIn(reset),
        .dataOut(syncReset)
    );

    top topInst(
        .clk(divClk),
        .en(1'b1),
        .reset(syncReset),
        .gpioPorts(gpioPorts)
    );
    
    // PLLE2_BASE: Base Phase Locked Loop (PLL)
    //             Artix-7
    // Xilinx HDL Language Template, version 2023.2
    PLLE2_BASE #(
      .CLKFBOUT_MULT(8),      // Multiply value for all CLKOUT, (2-64)
      .CLKIN1_PERIOD(10.000), // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT0_DIVIDE(16),
      .DIVCLK_DIVIDE(1)      // Master division value, (1-56)
    )
    PLLE2_BASE_inst (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(divClk),      // 1-bit output: CLKOUT0
      .CLKOUT1(),             // 1-bit output: CLKOUT1
      .CLKOUT2(),             // 1-bit output: CLKOUT2
      .CLKOUT3(),             // 1-bit output: CLKOUT3
      .CLKOUT4(),             // 1-bit output: CLKOUT4
      .CLKOUT5(),             // 1-bit output: CLKOUT5
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(pllFeedback), // 1-bit output: Feedback clock
      .LOCKED(),              // 1-bit output: LOCK
      .CLKIN1(clk),        // 1-bit input: Input clock
      // Control Ports: 1-bit (each) input: PLL control ports
      .PWRDWN(1'b0),          // 1-bit input: Power-down
      .RST(1'b0),             // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(pllFeedback)   // 1-bit input: Feedback clock
    );
    // End of PLLE2_BASE_inst instantiation

endmodule

`endif // __FILE_VESPTOP_V
