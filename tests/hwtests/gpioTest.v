`include "rtl/components/gpio.v"
`include "tests/testConstants.vh"

module gpioTest();

    reg [2:0] regSel;
    reg clk, reset, we;
    wire [31:0] dataOut;
    reg [31:0] dataIn;
    wire [15:0] ports;
    reg [15:0] portsReg;

    assign ports = portsReg;

    gpio dut (
        .regSel(regSel),
        .we(we),
        .reset(reset),
        .clk(clk),
        .di(dataIn),
        .do(dataOut),
        .ports(ports)
    );

    initial begin
        $dumpfile("test");
		$dumpvars;

        reset <= 1;
        we <= 0;
        #2;
        reset <= 0;
        #5;

        /* check if reset was done */
        regSel = 3'b000;
        #1;
        `ASSERT(dut.GPIOWR_A === 0 && dataOut === dut.GPIOWR_A, "GPIOWR_A does not match dataOut.");
        regSel = 3'b001;
        #1;
        `ASSERT(dut.GPIODIR_A === 0 && dataOut === dut.GPIODIR_A, "GPIODIR_A does not match dataOut.");
        regSel = 3'b011;
        #1;
        `ASSERT(dut.GPIOWR_B === 0 && dataOut === dut.GPIOWR_B, "GPIOWR_B does not match dataOut.");
        regSel = 3'b100;
        #1;
        `ASSERT(dut.GPIODIR_B === 0 && dataOut === dut.GPIODIR_B, "GPIODIR_B does not match dataOut.");

        /* check if dataOut matches what is put on the A ports */
        portsReg = 16'b1111111100000000;
        regSel = 3'b010;
        #1;
        `ASSERT(dataOut[7:0] === dut.ports[7:0], "dataOut does not match what was written to A ports.");
        
        /* check if dataOut matches what is put on the B ports */
        regSel = 3'b101; // can be anything > 3'b100
        #1;
        `ASSERT(dataOut[7:0] === dut.ports[15:8], "dataOut does not match what was written to B ports.");

        /* test writing to A ports */
        portsReg = {16{1'bZ}}; // third state has to be simulated
        // write data to GPIOWR_A that will be written to ports in the next step
        dataIn = 32'hFFFF_FFFF;
        regSel = 3'b000;
        we = 1;
        #2;
        `ASSERT(dataIn[7:0] === dut.GPIOWR_A, "dataIn was not written to GPIOWR_A.");
        // make GPIO_A outputs
        regSel = 3'b001;
        #2;
        `ASSERT(dataIn[7:0] === dut.GPIODIR_A, "dataIn was not written to GPIODIR_A.");
        we = 0;
        // check if data was written to A ports
        `ASSERT(dut.ports[7:0] === dataIn[7:0], "A ports do not match GPIOWR_A values.")

        #5;
        $display(`ASSERT_SUCCESS);
        $finish;
    end

    always begin
        clk <= 1; #1;
        clk <= 0; #1;
    end

    /* debug info */
    // always @(*) begin
    //     $display (
    //         "GPIOWR_A: %b\n", dut.GPIOWR_A,
    //         "GPIODIR_A: %b\n", dut.GPIODIR_A,
    //         "GPIOWR_B: %b\n", dut.GPIOWR_B,
    //         "GPIODIR_B: %b\n", dut.GPIODIR_B,
    //         "\n",
    //         "reset: %b\n", reset,
    //         "regSel: %b\n", regSel,
    //         "we: %b\n", we,
    //         "dataIn: %b\n", dataIn,
    //         "dataOut: %b\n", dataOut,
    //         "A ports %b\n", ports[7:0],
    //         "B ports %b\n", ports[15:8],
    //         "-------------------------------------\n"
    //     );
    // end

endmodule