`include "src/components/alu.v"

module aluTest();
	reg [31:0] op1, op2;
    reg [3:0] ctrl;
    wire [31:0] res;
    wire zero;

	alu #(32) ALU
    (
        .op1(op1),
        .op2(op2),
        .ctrl(ctrl),
        .zero(zero),
        .res(res)
    );
    
    initial begin
		$dumpfile("test");
		$dumpvars;

        $display("ALU test begin");

        op1 = -16;
        op2 = -5;
        ctrl = 0; // +
        #1;
        if (res != -21) begin
            $display("ADD error: op1=%b, op2=%b, zero=%b, res=%b", op1, op2, zero, res);
            $finish;
        end
        
        #1;

        op1 = -16;
        op2 = 5;
        ctrl = 0; // +
        #1;
        if (res != -11) begin
            $display("ADD error: op1=%b, op2=%b, zero=%b, res=%b", op1, op2, zero, res);
            $finish;
        end

        #1;

        op1 = 16;
        op2 = 5;
        ctrl = 1; // -
        #1;
        if (res != 11) begin
            $display("SUB error: op1=%b, op2=%b, zero=%b, res=%b", op1, op2, zero, res);
            $finish;
        end
        
        #1;

        op1 = -5;
        op2 = -16;
        ctrl = 1; // -
        #1;
        if (res != 11) begin
            $display("SUB error: op1=%b, op2=%b, zero=%b, res=%b", op1, op2, zero, res);
            $finish;
        end

        #1;

        op1 = 16;
        op2 = -5;
        ctrl = 8; // <s
        #1;
        if (res != 0) begin
            $display("SLT error: op1=%b, op2=%b, zero=%b, res=%b", op1, op2, zero, res);
            $finish;
        end
        
        #1;

        op1 = 16;
        op2 = 16;
        ctrl = 1; // -
        #1;
        if (res != 0 || zero != 1) begin
            $display("SUB error: op1=%b, op2=%b, zero=%b, res=%b", op1, op2, zero, res);
            $finish;
        end

		#1; $finish;
	end

endmodule