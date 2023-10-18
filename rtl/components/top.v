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
    input sysClk,
    input sysRes
);

    wire dataBusWE;
    wire [3:0] writeMask;
    wire [31:0] instrBusAddr, instrBusData, dataBusAddr, dataBusDataWrite,
                dataBusDataRead;
    
    `ifdef SPLIT_MEMORY
        instructionMemory #(
            .WORD_CNT(`INSTR_MEM_WORD_CNT)
        ) instrMemInst (
            .a(instrBusAddr),
            .d(instrBusData)
        );

        dataMemory #(
            .WORD_CNT(`DATA_MEM_WORD_CNT)
        ) dataMemInst (
            .clk(sysClk),
            .reset(sysRes),
            .we(dataBusWE),
            .mask(writeMask),
            .a(dataBusAddr),
            .di(dataBusDataWrite),
            .do(dataBusDataRead)
        );

    `else
        ram #(
            .WORD_CNT(`RAM_WORD_CNT)
        ) ramInst (
            .a1(instrBusAddr),
            .do1(instrBusData),

            .a2(dataBusAddr),
            .di2(dataBusDataWrite),
            .do2(dataBusDataRead),
            .m2(writeMask),
            .we2(dataBusWE),
            .clk(sysClk)
        );
    `endif // SPLIT_MEMORY

    cpu cpuInst (
        .clk(sysClk),
        .reset(sysRes),

        .instruction(instrBusData),
        .PC(instrBusAddr),

        .memAddr(dataBusAddr),
        .memReadData(dataBusDataRead),
        .memWriteData(dataBusDataWrite),
        .memWr(dataBusWE),
        .wrMask(writeMask)
    );

endmodule

`endif // __FILE_TOP_V