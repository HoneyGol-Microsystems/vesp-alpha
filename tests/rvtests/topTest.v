`include "src/components/top.v"
`include "src/constants.vh"

`define __MKPY_CURRENT_TEST "PATH_TO_HEX"
`define OPCODE_PASS               32'b1
`define OPCODE_FAIL               32'b0
`define PC_STOP             'ha4

`define MAX_QUEUE_SIZE      10

module topTest();
    
    reg clk, reset;
    integer i;
    integer pcValuesLog [`MAX_QUEUE_SIZE - 1:0];
    integer pcValuesLogPtr = 0;

    top dut(
        .sysClk(clk),
        .sysRes(reset)
    );

    initial begin

        $dumpfile("test");
		$dumpvars;
        $readmemh(`__MKPY_CURRENT_TEST, dut.ramInst.RAM, 0, `RAM_WORD_CNT-1);

        reset <= 1;
        #1;
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
        /* inner signals */
        // $display (
        //     "instr: %b (h%h)\n", dut.cpuInst.instruction, dut.cpuInst.instruction,
        //     "opcode: %b\n", dut.cpuInst.controllerInst.opcode,
        //     "funct3: %b\n", dut.cpuInst.controllerInst.funct3,
        //     "PC: h%h\n", dut.cpuInst.PC,
        //     "nextPC: h%h\n", dut.cpuInst.nextPC,
        //     "imm: %b (h%h)\n", dut.cpuInst.imm, dut.cpuInst.imm,
        //     "immPC: h%h\n", dut.cpuInst.immPC,
        //     "branchTarget: h%h\n", dut.cpuInst.branchTarget,
        //     "branch: %b\n", dut.cpuInst.branch,
        //     "ALUOp1: %b (h%h)\n", dut.cpuInst.src1, dut.cpuInst.src1,
        //     "ALUOp2: %b (h%h)\n", dut.cpuInst.src2, dut.cpuInst.src2,
        //     "ALUCtrl: %b\n", dut.cpuInst.ALUCtrl,
        //     "ALURes: %b (h%h)\n", dut.cpuInst.ALURes, dut.cpuInst.ALURes,
        //     "ALUZero: %b\n", dut.cpuInst.ALUZero,
        //     "ALUSrc1: %b\n", dut.cpuInst.ALUSrc1,
        //     "ALUSrc2: %b\n", dut.cpuInst.ALUSrc2,
        //     "regWr: %b\n", dut.cpuInst.regWr,
        //     "regDataSel: %b\n", dut.cpuInst.regDataSel,
        //     "memToReg: %b", dut.cpuInst.memToReg
        // );

        /* register contents */
        // for (i = 0; i <= 31; i++) begin
        //     $display("r%0d: %b (h%h)", i, dut.cpuInst.registerFile32Inst.rf[i], dut.cpuInst.registerFile32Inst.rf[i]);
        // end
        // $display("------------------------------------------");

        if (pcValuesLogPtr >= `MAX_QUEUE_SIZE - 1) begin
            pcValuesLogPtr = 0;
        end

        pcValuesLog[pcValuesLogPtr] = dut.cpuInst.PC;
        pcValuesLogPtr++;

        if (dut.instrBusData === `OPCODE_PASS) begin
            $display(`ASSERT_SUCCESS);
            $finish;
        end

        if (dut.instrBusData === `OPCODE_FAIL) begin
            $display(`ASSERT_FAIL);
            
            $display("Last PC values dump:");
            for(integer currentPc = pcValuesLogPtr; currentPc < `MAX_QUEUE_SIZE; currentPc++)
                $display("%x", pcValuesLog[currentPc]);
            for(integer currentPc = 0; currentPc < pcValuesLogPtr; currentPc++)
                $display("%x", pcValuesLog[currentPc]);

            $finish;
        end

        /* stop on certain PC for debugging purposes */
        // if (dut.cpuInst.PC === `PC_STOP) begin
        //     $display(`ASSERT_DEBUG_STOP);
        //     $finish;
        // end
    end
    
endmodule