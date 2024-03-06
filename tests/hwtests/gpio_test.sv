`include "rtl/components/gpio.sv"
`include "tests/test_constants.vh"

module gpio_test();

    logic clk, reset, we;
    logic [2:0] reg_sel;
    logic [31:0] data_out, data_in;
    wire  [15:0] ports;
    logic [15:0] ports_reg;

    assign ports = ports_reg;

    module_gpio dut (
        .reg_sel(reg_sel),
        .we(we),
        .reset(reset),
        .clk(clk),
        .din(data_in),
        .dout(data_out),
        .ports(ports)
    );

    initial begin
        reset <= 1;
        we <= 0;
        #2;
        reset <= 0;
        #6;

        /* check if reset was done */
        reg_sel = 3'b000;
        #2;
        `ASSERT(dut.GPIOWR_A === 0 && data_out === dut.GPIOWR_A, "GPIOWR_A does not match data_out.");
        reg_sel = 3'b001;
        #2;
        `ASSERT(dut.GPIODIR_A === 0 && data_out === dut.GPIODIR_A, "GPIODIR_A does not match data_out.");
        reg_sel = 3'b011;
        #2;
        `ASSERT(dut.GPIOWR_B === 0 && data_out === dut.GPIOWR_B, "GPIOWR_B does not match data_out.");
        reg_sel = 3'b100;
        #2;
        `ASSERT(dut.GPIODIR_B === 0 && data_out === dut.GPIODIR_B, "GPIODIR_B does not match data_out.");

        /* check if data_out matches what is put on the A ports */
        ports_reg = 16'b1111111100000000;
        reg_sel = 3'b010;
        #2;
        `ASSERT(data_out[23:16] === dut.ports[7:0], "data_out does not match what was written to A ports.");
        
        /* check if data_out matches what is put on the B ports */
        reg_sel = 3'b101; // can be anything > 3'b100
        #2;
        `ASSERT(data_out[15:8] === dut.ports[15:8], "data_out does not match what was written to B ports.");

        /* test writing to A ports */
        ports_reg = {16{1'bZ}}; // third state has to be simulated
        // write data to GPIOWR_A that will be written to ports in the next step
        data_in = 32'hFFFF_FFFF;
        reg_sel = 3'b000;
        we = 1;
        #2;
        `ASSERT(data_in[7:0] === dut.GPIOWR_A, "data_in was not written to GPIOWR_A.");
        // make GPIO_A outputs
        reg_sel = 3'b001;
        #2;
        `ASSERT(data_in[7:0] === dut.GPIODIR_A, "data_in was not written to GPIODIR_A.");
        we = 0;
        // check if data was written to A ports
        `ASSERT(dut.ports[7:0] === data_in[7:0], "A ports do not match GPIOWR_A values.")

        /* test writing to B ports */
        ports_reg = {16{1'bZ}}; // third state has to be simulated
        // write data to GPIOWR_B that will be written to ports in the next step
        data_in = 32'hFFFF_FFFF;
        reg_sel = 3'b011;
        we = 1;
        #2;
        `ASSERT(data_in[7:0] === dut.GPIOWR_B, "data_in was not written to GPIOWR_B.");
        // make GPIO_B outputs
        reg_sel = 3'b100;
        #2;
        `ASSERT(data_in[7:0] === dut.GPIODIR_B, "data_in was not written to GPIODIR_B.");
        we = 0;
        // check if data was written to B ports
        `ASSERT(dut.ports[15:8] === data_in[7:0], "A ports do not match GPIOWR_B values.")

        #5;
        $display(`ASSERT_SUCCESS);
        $finish;
    end

    always begin
        clk <= 1; #1;
        clk <= 0; #1;
    end

endmodule