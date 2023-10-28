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
`include "rtl/components/addressDecoder.v"
`include "rtl/components/gpio.v"

module top (
    input sysClk,
    input sysRes,
    inout [15:0] gpioPorts
);

    wire dataBusWE, weMem, weGpio;
    wire [2:0] outSel;
    wire [3:0] writeMask;
    wire [31:0] instrBusAddr, instrBusData, dataBusAddr, dataBusDataWrite,
                dataMemDO, gpioDO;
    
    reg  [31:0] dataBusDataRead;
    
    addressDecoder addressDecoderInst(
        .we(dataBusWE),
        .a(dataBusAddr),

        .outsel(outSel),
        .wemem(weMem),
        .wegpio(weGpio)
    );

    gpio gpioInst(
        .regSel(dataBusAddr[2:0]),
        .we(weGpio),
        .reset(sysRes),
        .clk(sysClk),
        
        .di(dataBusDataWrite),
        .do(gpioDO),
        .ports(gpioPorts)
    );

    `ifdef SPLIT_MEMORY
        instructionMemory #(
            .WORD_CNT(`INSTR_MEM_WORD_CNT),
            .MEM_FILE("")
        ) instrMemInst (
            .a(instrBusAddr),
            .d(instrBusData)
        );

        dataMemory #(
            .WORD_CNT(`DATA_MEM_WORD_CNT),
            .MEM_FILE("")
        ) dataMemInst (
            .clk(sysClk),
            .we(dataBusWE),
            .mask(writeMask),
            .a(dataBusAddr),
            .di(dataBusDataWrite),
            .do(dataMemDO)
        );

    `else
        ram #(
            .WORD_CNT(`RAM_WORD_CNT),
            .MEM_FILE("")
        ) ramInst (
            .a1(instrBusAddr),
            .do1(instrBusData),

            .a2(dataBusAddr),
            .di2(dataBusDataWrite),
            .do2(dataMemDO),
            .m2(writeMask),
            .we2(weMem),
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

    // CPU data read source select.
    always @(*) begin
        case (outSel)
            3'b000:  dataBusDataRead = dataMemDO;
            default: dataBusDataRead = gpioDO;
        endcase
    end

endmodule

`endif // __FILE_TOP_V