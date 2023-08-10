`include "src/components/top.v"
`include "src/constants.vh"

`define __MKPY_CURRENT_TEST "PATH_TO_HEX"
`define ECALL               32'b1110011
`define EBREAK              32'b100000000000001110011
`define PC_STOP             'ha4

module topTest();
    
    reg clk, reset;
    integer i;

    top dut(
        .sysClk(clk),
        .sysRes(reset)
    );

    initial begin

        $dumpfile("test");
		$dumpvars;
        $readmemh(`__MKPY_CURRENT_TEST, dut.ramMain.RAM);

        reset <= 1;
        #1;
        reset <= 0;
        #99999;

        $display("TIMEOUT");
        $finish;
    end

    always begin
		clk <= 1; #1;
        clk <= 0; #1;
	end

    always @(posedge clk) begin
        /* inner signals */
        // $display (
        //     "instr: %b (h%h)\n", dut.cpu.instruction, dut.cpu.instruction,
        //     "opcode: %b\n", dut.cpu.ctrler.opcode,
        //     "funct3: %b\n", dut.cpu.ctrler.funct3,
        //     "PC: h%h\n", dut.cpu.PC,
        //     "nextPC: h%h\n", dut.cpu.nextPC,
        //     "imm: %b (h%h)\n", dut.cpu.imm, dut.cpu.imm,
        //     "immPC: h%h\n", dut.cpu.immPC,
        //     "branchTarget: h%h\n", dut.cpu.branchTarget,
        //     "branch: %b\n", dut.cpu.branch,
        //     "ALUSrc1: %b (h%h)\n", dut.cpu.src1, dut.cpu.src1,
        //     "ALUSrc2: %b (h%h)\n", dut.cpu.src2, dut.cpu.src2,
        //     "ALUCtrl: %b\n", dut.cpu.ALUCtrl,
        //     "ALURes: %b (h%h)\n", dut.cpu.ALURes, dut.cpu.ALURes,
        //     "ALUZero: %b\n", dut.cpu.ALUZero,
        //     "ALUImm: %b\n", dut.cpu.ALUImm,
        //     "regWr: %b\n", dut.cpu.regWr,
        //     "regDataSel: %b\n", dut.cpu.regDataSel,
        //     "memToReg: %b", dut.cpu.memToReg
        // );

        /* register contents */
        // for (i = 0; i <= 31; i++) begin
        //     $display("r%0d: %b (h%h)", i, dut.cpu.regfile.rf[i], dut.cpu.regfile.rf[i]);
        // end
        // $display("------------------------------------------");

        if (dut.instrBusData == `ECALL) begin
            $display(`ASSERT_SUCCESS);
            $finish;
        end

        if (dut.instrBusData == `EBREAK) begin
            $display(`ASSERT_FAIL);
            $finish;
        end

        /* stop on certain PC for debugging purposes */
        // if (dut.cpu.PC == `PC_STOP) begin
        //     $display("DEBUG_STOP");
        //     $finish;
        // end
    end
    
endmodule