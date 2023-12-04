`include "rtl/components/top.v"
`include "rtl/constants.vh"

`define OPCODE_PASS         32'b1
`define OPCODE_FAIL         32'b0
`define PC_STOP             'ha4

module gpioTopTest();
    
    reg clk, reset;
    wire [15:0] ports;
    // reg [15:0] portsReg;
    // assign ports = portsReg;

    top dut(
        .clk(clk),
        .reset(reset),
        .gpioPorts(ports)
    );

    initial begin
        $readmemh("firmware_text.hex", dut.instrMemInst.ram, 0, `INSTR_MEM_WORD_CNT-1);
        $readmemh("firmware_data.hex", dut.dataMemInst.ram, 0, `DATA_MEM_WORD_CNT-1);

        reset <= 0;
        #5;
        reset <= 1;
        #5;
        reset <= 0;

        #99999;

        $display(`ASSERT_TIMEOUT);
        $finish;
    end

    always begin
		clk <= 1; #1;
        clk <= 0; #1;
	end

    always @(posedge clk) begin
        if (dut.iRead === `OPCODE_PASS) begin
            $display(`ASSERT_SUCCESS);
            $finish;
        end

        if (dut.iRead === `OPCODE_FAIL) begin
            $display(`ASSERT_FAIL);
            $finish;
        end

        /* stop on certain PC for debugging purposes */
        // if (dut.cpuInst.PC === `PC_STOP) begin
        //     $display(`ASSERT_DEBUG_STOP);
        //     $finish;
        // end
    end
    
endmodule