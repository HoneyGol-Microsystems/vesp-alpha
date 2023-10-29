`ifndef __FILE_CPU_V
`define __FILE_CPU_V

`include "rtl/constants.vh"
`include "rtl/components/controller.v"
`include "rtl/components/alu.v"
`include "rtl/components/immDecoder.v"
`include "rtl/components/registerFile32.v"
`include "rtl/components/extend.v"
`include "rtl/components/csr.v"
`include "rtl/components/interruptController.v"

module cpu (
    input             clk,
    input             reset,
    input      [31:0] instruction,
    input      [31:0] memRdData,
    output            memWE,  // write enable to data memory
    output     [3:0]  memMask,
    output reg [31:0] PC,
    output     [31:0] memAddr,
    output     [31:0] memWrData,
    output     [31:0] memWrDataSh
);

    // wire/reg declarations
    wire ALUZero, ALUToPC, memToReg, regWE, rs2ShiftSel,
         uext, csrWE, branch, mret, interrupt, irqBus,
         exception, intExc;
    wire [1:0] loadSel, maskSel, ALUSrc1, ALUSrc2;
    wire [2:0] regDataSel;
    wire [3:0] ALUCtrl;
    wire [4:0] rs2Shift;
    wire [15:0] dataLH;
    wire [30:0] intCode, excCode;
    wire [31:0] src1, rs1, rs2, ALURes, imm, immPC, branchTarget, regRes,
                dataExtLB, dataExtLH, PC4, csrOut, mepcOut, mtvecOut,
                mcauseOut, mcauseIn, nextPC, nextPCInt, branchMretTarget,
                intExcCode, nextMepc, ISRAddress;
    reg [3:0] mask;
    reg [7:0] dataLB;
    reg [31:0] regData, memData, src2;

    // module instantiations
    controller controllerInst (
        .instruction(instruction),
        .memAddr(memAddr),
        .ALUZero(ALUZero),
        .interrupt(interrupt),
        .clk(clk),
        .reset(reset),

        .ALUCtrl(ALUCtrl),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2),
        .ALUToPC(ALUToPC),
        .branch(branch),
        .loadSel(loadSel),
        .maskSel(maskSel),
        .memToReg(memToReg),
        .memWE(memWE),
        .regDataSel(regDataSel),
        .regWE(regWE),
        .rs2ShiftSel(rs2ShiftSel),
        .uext(uext),
        .csrWE(csrWE),
        .mret(mret),
        .exception(exception),
        .excCode(excCode)
    );

    alu #(
        .XLEN(`XLEN)
    ) aluInst (
        .op1(src1),
        .op2(src2),
        .ctrl(ALUCtrl),
        .zero(ALUZero),
        .res(ALURes)
    );

    immDecoder immDecoderInst (
        .instruction(instruction),
        .imm(imm)
    );

    registerFile32 #(
        .XLEN(`XLEN)
    ) registerFile32Inst (
        .a1(instruction[19:15]),
        .a2(instruction[24:20]),
        .a3(instruction[11:7]),
        .di3(regRes),
        .we3(regWE),
        .clk(clk),
        .rd1(rs1),
        .rd2(rs2)
    );

    interruptController #(
        .EXT_IRQ_COUNT(1)
    ) interruptControllerInst (
        .clk(clk),
        .irqBus(irqBus),
        .interrupt(interrupt),
        .intCode(intCode)
    );

    csr csrInst (
        .reset(reset),
        .clk(clk),
        .we(csrWE),
        .a(instruction[31:20]),
        .di(ALURes),
        .do(csrOut),
        .mepcDo(mepcOut),
        .mtvecDo(mtvecOut),
        .mcauseDo(mcauseOut),
        .mepcWe(intExc),
        .mcauseWe(intExc),
        .mepcDi(nextMepc),
        .mcauseDi(intExcCode)
    );

    extend #(
        .DATA_LEN(8),
        .RES_LEN(`XLEN)
    ) ext8to32 (
        .data(dataLB),
        .uext(uext),
        .res(dataExtLB)
    );

    extend #(
        .DATA_LEN(16),
        .RES_LEN(`XLEN)
    ) ext16to32 (
        .data(dataLH),
        .uext(uext),
        .res(dataExtLH)
    );

    // assignments (including 1bit muxes)
    assign PC4              = PC + 4;
    assign immPC            = imm + PC;
    assign branchTarget     = ALUToPC ? ALURes : immPC;
    assign src1             = ALUSrc1 ? imm : rs1;
    assign rs2Shift         = rs2ShiftSel ? {ALURes[1], 4'b0} : {ALURes[1:0], 3'b0};
    assign memWrData        = rs2;
    assign memWrDataSh      = rs2 << rs2Shift;
    assign memAddr          = ALURes;
    assign memMask          = mask << ALURes[1:0];
    assign dataLH           = ALURes[1] ? memRdData[31:16] : memRdData[15:0];
    assign regRes           = memToReg ? memData : regData;
    assign branchMretTarget = mret ? mepcOut : branchTarget;
    assign nextPC           = branch | mret ? branchMretTarget : PC4;
    assign nextPCInt        = intExc ? ISRAddress : nextPC;

    assign intExcCode       = {interrupt, interrupt ? intCode : excCode};
    assign intExc           = interrupt || exception;
    assign nextMepc         = exception ? PC : nextPC;

    // ISR decoder block
    assign ISRAddress       = (mcauseOut[31] && mtvecOut[0]) ? 
                                    {mtvecOut[31:2], 2'b00} + (mcauseOut << 2)
                                    :
                                    {mtvecOut[31:2], 2'b00};

    // PCREG
    always @(posedge clk) begin
        if (reset) begin
            PC <= 0;
        end else begin
            PC <= nextPCInt;
        end
    end

    // ALUSrc2 mux
    always @(*) begin
        case (ALUSrc2)
            2'b00:   src2 = rs2;
            2'b01:   src2 = imm;
            default: src2 = csrOut;
        endcase
    end

    // maskSel mux
    always @(*) begin
        case (maskSel)
            2'b00:   mask = 4'b0001;
            2'b01:   mask = 4'b0011;
            default: mask = 4'b1111;
        endcase
    end

    // regDataSel mux
    always @(*) begin
        case (regDataSel)
            3'b000:  regData = ALURes;
            3'b001:  regData = immPC;
            3'b010:  regData = imm;
            3'b011:  regData = PC4;
            default: regData = csrOut;
        endcase
    end

    // dataLB mux
    always @(*) begin
        case (ALURes[1:0])
            2'b00:   dataLB = memRdData[7:0];
            2'b01:   dataLB = memRdData[15:8];
            2'b10:   dataLB = memRdData[23:16];
            default: dataLB = memRdData[31:24];
        endcase
    end

    // loadSel mux
    always @(*) begin
        case (loadSel)
            2'b00:   memData = dataExtLB;
            2'b01:   memData = dataExtLH;
            default: memData = memRdData;
        endcase
    end

endmodule

`endif // __FILE_CPU_V