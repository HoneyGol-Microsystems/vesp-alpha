module alu #(
    parameter XLEN = 32 // width of operands
) (
    input [XLEN-1:0] op1, op2, // operands (unsigned)
    input [3:0] ctrl,          // ALU control
    output zero,               // zero result flag
    output reg [XLEN-1:0] res  // result
);

    // set zero flag
    assign zero = res ? 0 : 1;

    // decode operation
    always @(*) begin
        case (ctrl)
            4'b0000: res = $signed(op1) + $signed(op2);
            4'b0001: res = $signed(op1) - $signed(op2);
            4'b0010: res = op1 & op2;
            4'b0011: res = op1 | op2;
            4'b0100: res = op1 ^ op2;
            4'b0101: res = op1 << op2;
            4'b0110: res = op1 >> op2;
            4'b0111: res = $signed(op1) >>> op2;
            4'b1000: res = $signed(op1) < $signed(op2);
            4'b1001: res = op1 < op2;
            default: res = 0;
        endcase
    end

endmodule