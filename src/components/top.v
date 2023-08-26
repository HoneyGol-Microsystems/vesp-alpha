`ifndef __FILE_TOP_V
`define __FILE_TOP_V

`include "src/components/cpu.v"
`include "src/components/ram.v"
`include "src/constants.vh"

module top (
    input sysClk,
    input sysRes
);

    wire dataBusWE;
    wire [3:0] writeMask;
    wire [31:0] instrBusAddr, instrBusData, dataBusAddr, dataBusDataWrite,
                dataBusDataRead;
    
    ram #(
        .WORD_CNT(`RAM_WORD_CNT),
        .MEM_FILE("asm/led.hex")
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