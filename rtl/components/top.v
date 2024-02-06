`ifndef __FILE_TOP_V
`define __FILE_TOP_V

 // `define SPLIT_MEMORY /* whether to use Harvard or Von-Neumann memory architecture */

(* dont_touch = "yes" *) module top (
    input         clk,
    input         reset,
    inout  [15:0] gpioPorts,
    input         rx,
    output        tx
);

    wire dWE, dataMemWE, gpioWE, uartRE, uartWE;
    wire [2:0] dReadSel;
    wire [3:0] dMask;
    wire [31:0] iAddr, iRead, dAddr, dWrite, dataMemDO, gpioDO, uartDOUT;
    reg [31:0] dRead;

    addressDecoder addressDecoderInst (
        .we(dWE),
        .a(dAddr),
        .outsel(dReadSel),
        .wemem(dataMemWE),
        .wegpio(gpioWE),
        .reuart0(uartRE),
        .weuart0(uartWE)
    );

    gpio gpioInst (
        .regSel(dAddr[2:0]),
        .we(gpioWE),
        .reset(reset),
        .clk(clk),
        .di(dWrite),
        .do(gpioDO),
        .ports(gpioPorts)
    );

    module_uart_top #(
        .TX_QUEUE_SIZE(16),
        .RX_QUEUE_SIZE(16)
    ) uartInst (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .re(uartRE),
        .we(uartWE),
        .regsel(dAddr[2:0]),
        .din(dWrite),

        .tx(tx),
        .par_irq(),
        .stop_bit_irq(),
        .dout(uartDOUT)
    );

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
            3'b001:  dRead = gpioDO;
            default: dRead = uartDOUT;
        endcase
    end

endmodule

`endif // __FILE_TOP_V