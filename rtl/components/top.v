`ifndef __FILE_TOP_V
`define __FILE_TOP_V

`define SPLIT_MEMORY /* whether to use Harvard or Von-Neumann memory architecture */

(* dont_touch = "yes" *) module top (
    input clk,
    input reset,
    inout [15:0] gpioPorts
);

    wire dWE, dataMemWE, gpioWE;
    wire [2:0] dReadSel;
    wire [3:0] dMask;
    wire [31:0] iAddr, iRead, dAddr, dWrite, dataMemDO, gpioDO;
    reg [31:0] dRead;

    addressDecoder addressDecoderInst (
        .we(dWE),
        .a(dAddr),
        .outsel(dReadSel),
        .wemem(dataMemWE),
        .wegpio(gpioWE)
    );

    gpio gpioInst (
        .regSel(dAddr[2:0]),
        .we(gpioWE),
        .reset(reset),
        .clk(clk),
        .di(dWrite),
        .dout(gpioDO),
        .ports(gpioPorts)
    );

    `ifdef SPLIT_MEMORY
        instructionMemory #(
            .WORD_CNT(`INSTR_MEM_WORD_CNT),
            .MEM_FILE("software/firmware_text.mem")
        ) instrMemInst (
            .a(iAddr),
            .d(iRead)
        );

        dataMemory #(
            .WORD_CNT(`DATA_MEM_WORD_CNT),
            .MEM_FILE("software/firmware_data.mem")
        ) dataMemInst (
            .clk(clk),
            .we(dWE),
            .mask(dMask),
            .a(dAddr),
            .di(dWrite),
            .do(dataMemDO)
        );

    `else
        ram #(
            .WORD_CNT(`RAM_WORD_CNT),
            .MEM_FILE("")
        ) ramInst (
            .a1(iAddr),
            .do1(iRead),

            .a2(dAddr),
            .di2(dWrite),
            .do2(dataMemDO),
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
        .memWE(dWE),
        .memMask(dMask)
    );

    // CPU data read source select.
    always @(*) begin
        case (dReadSel)
            3'b000:  dRead = dataMemDO;
            default: dRead = gpioDO;
        endcase
    end

endmodule

`endif // __FILE_TOP_V