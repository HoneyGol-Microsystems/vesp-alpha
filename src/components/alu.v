`ifndef __FILE_ALU_V
`define __FILE_ALU_V

module alu #(
    parameter XLEN = 32 // width of operands
) (
    input      [XLEN-1:0] op1, op2, // operands (unsigned)
    input      [3:0]      ctrl,     // ALU control
    output                zero,     // zero result flag
    output reg [XLEN-1:0] res       // result
);

    // set zero flag
    assign zero = res ? 0 : 1;

    // decode operation
    always @(*) begin
        case (ctrl)
            4'b0000: res = op1;
            4'b0001: res = $signed(op1) + $signed(op2);
            4'b0010: res = $signed(op1) - $signed(op2);
            4'b0011: res = op1 & op2;
            4'b0100: res = op1 & ~op2;
            4'b0101: res = op1 | op2;
            4'b0110: res = op1 ^ op2;
            4'b0111: res = op1 << op2[4:0]; // shift amount is encoded in the lower 5 bits
            4'b1000: res = op1 >> op2[4:0];
            4'b1001: res = $signed(op1) >>> op2[4:0];
            4'b1010: res = $signed(op1) < $signed(op2);
            default: res = op1 < op2;
        endcase
    end

endmodule

`endif // __FILE_ALU_V