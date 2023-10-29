`ifndef __FILE_TOP_V
`define __FILE_TOP_V

// `define SPLIT_MEMORY /* whether to use Harvard or Von-Neumann memory architecture */

`include "rtl/components/cpu.v"
`ifdef SPLIT_MEMORY
    `include "rtl/components/instructionMemory.v"
    `include "rtl/components/dataMemory.v"
`else
    `include "rtl/components/ram.v"
`endif // SPLIT_MEMORY
`include "rtl/constants.vh"

module top (
    input clk,
    input reset
);

    wire dWE;
    wire [3:0] dMask;
    wire [31:0] iAddr, iRead, dAddr, dWrite, dWriteSh, dRead;
    
    `ifdef SPLIT_MEMORY
        instructionMemory #(
            .WORD_CNT(`INSTR_MEM_WORD_CNT),
            .MEM_FILE("")
        ) instrMemInst (
            .a(iAddr),
            .d(iRead)
        );

        dataMemory #(
            .WORD_CNT(`DATA_MEM_WORD_CNT),
            .MEM_FILE("")
        ) dataMemInst (
            .clk(clk),
            .we(dWE),
            .mask(dMask),
            .a(dAddr),
            .di(dWrite),
            .do(dRead)
        );

    `else
        ram #(
            .WORD_CNT(`RAM_WORD_CNT),
            .MEM_FILE("")
        ) ramInst (
            .a1(iAddr),
            .do1(iRead),

            .a2(dAddr),
            .di2(dWriteSh),
            .do2(dRead),
            .m2(dMask),
            .we2(dWE),
            .clk(clk)
        );
    `endif // SPLIT_MEMORY

    cpu cpuInst (
        .clk(clk),
        .reset(reset),

        .instruction(iRead),
        .PC(iAddr),

        .memAddr(dAddr),
        .memRdData(dRead),
        .memWrData(dWrite),
        .memWrDataSh(dWriteSh),
        .memWE(dWE),
        .memMask(dMask)
    );

endmodule

`endif // __FILE_TOP_V