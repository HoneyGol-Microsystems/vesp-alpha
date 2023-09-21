`ifndef __FILE_TOP_V
`define __FILE_TOP_V

// `define SPLIT_MEMORY /* whether to use Harvard or Von-Neumann memory architecture */

`include "src/components/cpu.v"
`ifdef SPLIT_MEMORY
    `include "src/components/instructionMemory.v"
    `include "src/components/dataMemory.v"
`else
    `include "src/components/ram.v"
`endif // SPLIT_MEMORY
`include "src/constants.vh"

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
            .WORD_CNT(`INSTR_MEM_WORD_CNT),
            .MEM_DATA("asm/led_text.hex")
        ) instrMemInst (
            .a(instrBusAddr),
            .d(instrBusData)
        );

        dataMemory #(
            .WORD_CNT(`DATA_MEM_WORD_CNT),
            .MEM_DATA("asm/led_data.hex")
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
            .WORD_CNT(`RAM_WORD_CNT),
            .MEM_DATA("asm/led.hex")
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