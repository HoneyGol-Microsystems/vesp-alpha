`ifndef __FILE_ALU_V
`define __FILE_ALU_V

module alu #(
    parameter XLEN = 32 // width of operands
) (
    input      [XLEN-1:0] op1, op2, // operands (unsigned)
    input      [4:0]      ctrl,     // ALU control
    output                zero,     // zero result flag
    output reg [XLEN-1:0] res       // result
);

    // set zero flag
    assign zero = res ? 0 : 1;
    reg [31:0] mulTmp;

    // decode operation
    always @(*) begin
        case (ctrl)
            5'b00000: res = op1;
            5'b00001: res = $signed(op1) + $signed(op2);
            5'b00010: res = $signed(op1) - $signed(op2);
            5'b00011: res = op1 & op2;
            5'b00100: res = op1 & ~op2;
            5'b00101: res = op1 | op2;
            5'b00110: res = op1 ^ op2;
            5'b00111: res = op1 << op2[4:0]; // shift amount is encoded in the lower 5 bits
            5'b01000: res = op1 >> op2[4:0];
            5'b01001: res = $signed(op1) >>> op2[4:0];
            5'b01010: res = $signed(op1) < $signed(op2);
            5'b01011: res = op1 < op2;
            5'b01100: begin // MULH
                {res, mulTmp} = { {32{op1[31]}}, $signed(op1) } * { {32{op2[31]}}, $signed(op2) };
            end
            5'b01101: res = $signed(op1) * $signed(op2); // MUL
            5'b01110: begin // MULHSU
                {res, mulTmp} = { {32{op1[31]}}, $signed(op1) } * {32'b0, op2};
            end
            5'b01111: begin // MULHU
                {res, mulTmp} = {32'b0, op1} * {32'b0, op2};
            end
            5'b10000: res = op2 ? $signed(op1) / $signed(op2) : -1; // DIV
            5'b10001: res = op2 ? op1 / op2 : -1; // DIVU
            5'b10010: begin // REM
                res = op2 ? (op1[31] ? -op1 : op1) % (op2[31] ? -op2 : op2) : op1; // calculate remainder with abs
                res = op1[31] ? -res : res; // resolve sign of the result
            end
            5'b10011: res = op2 ? op1 % op2 : op1; // REMU
            default:  res = 0;
        endcase
    end

endmodule

`endif // __FILE_ALU_V