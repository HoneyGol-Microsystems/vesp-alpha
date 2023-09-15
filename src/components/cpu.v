`ifndef __FILE_CPU_V
`define __FILE_CPU_V

`include "src/constants.vh"
`include "src/components/controller.v"
`include "src/components/alu.v"
`include "src/components/immDecoder.v"
`include "src/components/registerFile32.v"
`include "src/components/extend.v"
`include "src/components/csr.v"

module cpu (
    input             clk,
    input             reset,
    input      [31:0] instruction,
    input      [31:0] memReadData,
    output            memWr,  // write enable to data memory
    output     [3:0]  wrMask,
    output reg [31:0] PC,
    output     [31:0] memAddr,
    output     [31:0] memWriteData
);

    // wire/reg declarations
    wire ALUZero, ALUToPC, branch, memToReg, regWr, rs2ShiftSel,
         uext, csrWr, mcauseWr, mepcWr;
    wire [1:0] loadSel, maskSel, ALUSrc1, ALUSrc2;
    wire [2:0] regDataSel;
    wire [3:0] ALUCtrl;
    wire [4:0] rs2Shift;
    wire [15:0] dataLH;
    wire [31:0] src1, rs1, rs2, ALURes, imm, immPC, branchTarget,
                regRes, dataExtLB, dataExtLH, nextPC, PC4, csrOut,
                mepcOut, mtvecOut, mcauseOut, mepcIn, mcauseIn;
    reg [3:0] mask;
    reg [7:0] dataLB;
    reg [31:0] regData, memData, src2;

    // module instantiations
    controller controllerInst (
        .instruction(instruction),
        .memAddr(memAddr),
        .ALUZero(ALUZero),
        .ALUCtrl(ALUCtrl),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2),
        .ALUToPC(ALUToPC),
        .branch(branch),
        .loadSel(loadSel),
        .maskSel(maskSel),
        .memToReg(memToReg),
        .memWr(memWr),
        .regDataSel(regDataSel),
        .regWr(regWr),
        .rs2ShiftSel(rs2ShiftSel),
        .uext(uext),
        .csrWr(csrWr)
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
        .we3(regWr),
        .clk(clk),
        .rd1(rs1),
        .rd2(rs2)
    );

    csr csrInst (
        .reset(reset),
        .clk(clk),
        .we(csrWr),
        .a(instruction[31:20]),
        .di(ALURes),
        .do(csrOut),
        .mepcDo(mepcOut),
        .mtvecDo(mtvecOut),
        .mcauseDo(mcauseOut),
        .mepcWe(mepcWr),
        .mcauseWe(mcauseWr),
        .mepcDi(mepcIn),
        .mcauseDi(mcauseIn)
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
    assign PC4          = PC + 4;
    assign immPC        = imm + PC;
    assign branchTarget = ALUToPC ? ALURes : immPC;
    assign nextPC       = branch ? branchTarget : PC4;
    assign src1         = ALUSrc1 ? imm : rs1;
    assign rs2Shift     = rs2ShiftSel ? {ALURes[1], 4'b0} : {ALURes[1:0], 3'b0};
    assign memWriteData = rs2 << rs2Shift;
    assign memAddr      = ALURes;
    assign wrMask       = mask << ALURes[1:0];
    assign dataLH       = ALURes[1] ? memReadData[31:16] : memReadData[15:0];
    assign regRes       = memToReg ? memData : regData;

    // PCREG
    always @(posedge clk) begin
        if (reset) begin
            PC <= 0;
        end else begin
            PC <= nextPC;
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
            2'b00:   dataLB = memReadData[7:0];
            2'b01:   dataLB = memReadData[15:8];
            2'b10:   dataLB = memReadData[23:16];
            default: dataLB = memReadData[31:24];
        endcase
    end

    // loadSel mux
    always @(*) begin
        case (loadSel)
            2'b00:   memData = dataExtLB;
            2'b01:   memData = dataExtLH;
            default: memData = memReadData;
        endcase
    end

endmodule

`endif // __FILE_CPU_V