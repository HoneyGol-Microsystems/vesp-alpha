`include "src/constants.vh"
`include "src/components/controller.v"
`include "src/components/alu.v"
`include "src/components/immDecoder.v"
`include "src/components/registerFile32.v"
`include "src/components/extend.v"

module cpu (
    input             clk,
    input             reset,
    input      [31:0] instruction,
    input      [31:0] memReadData,
    output            memWr,  // write enable to data memory
    output            except, // exception TODO: type of exception
    output     [3:0]  wrMask,
    output reg [31:0] PC,
    output     [31:0] memAddr,
    output     [31:0] memWriteData
);

    // wire/reg declarations
    wire ALUZero, ALUImm, ALUToPC, branch, memToReg, regWr,
         rs2ShiftSel, uext;
    wire [1:0] loadSel, maskSel, regDataSel;
    wire [3:0] ALUCtrl;
    wire [4:0] rs2Shift;
    wire [15:0] dataLH;
    wire [31:0] src1, src2, rs1, rs2, ALURes, imm, immPC, branchTarget,
                regRes, dataExtLB, dataExtLH, nextPC, PC4;
    reg [3:0] mask;
    reg [7:0] dataLB;
    reg [31:0] regData, memData;

    // module instantiations
    controller ctrler
    (
        .instruction(instruction),
        .memAddr(memAddr),
        .ALUZero(ALUZero),
        .ALUCtrl(ALUCtrl),
        .ALUImm(ALUImm),
        .ALUToPC(ALUToPC),
        .branch(branch),
        .loadSel(loadSel),
        .maskSel(maskSel),
        .memToReg(memToReg),
        .memWr(memWr),
        .regDataSel(regDataSel),
        .regWr(regWr),
        .rs2ShiftSel(rs2ShiftSel),
        .uext(uext)
    );

    alu #(`XLEN) ALU
    (
        .op1(src1),
        .op2(src2),
        .ctrl(ALUCtrl),
        .zero(ALUZero),
        .res(ALURes)
    );

    immDecoder immDcder
    (
        .instruction(instruction),
        .imm(imm)
    );

    registerFile32 #(`XLEN) regfile
    (
        .a1(instruction[19:15]),
        .a2(instruction[24:20]),
        .a3(instruction[11:7]),
        .di3(regRes),
        .we3(regWr),
        .clk(clk),
        .rd1(rs1),
        .rd2(rs2)
    );

    extend #(8, `XLEN) ext8to32
    (
        .data(dataLB),
        .uext(uext),
        .res(dataExtLB)
    );

    extend #(16, `XLEN) ext16to32
    (
        .data(dataLH),
        .uext(uext),
        .res(dataExtLH)
    );

    // assignments (including 1bit muxes)
    assign PC4          = PC + 4;
    assign immPC        = imm + PC;
    assign branchTarget = ALUToPC ? ALURes : immPC;
    assign nextPC       = branch ? branchTarget : PC4;
    assign src1         = rs1;
    assign src2         = ALUImm ? imm : rs2;
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
            2'b00:   regData = ALURes;
            2'b01:   regData = immPC;
            2'b10:   regData = imm;
            default: regData = PC4;
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