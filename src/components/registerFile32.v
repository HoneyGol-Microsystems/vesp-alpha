/* register file with 32 GPR's with parametrized length */
module registerFile32 #(
    parameter XLEN = 32 // width of registers
) (
    input [4:0] a1, a2, a3,    // address to src (a1, a2) and dest (a3) register
    input [XLEN-1:0] di3,      // data to write to dest register
    input we3,                 // write enable for dest register
    input clk,                 // clock
    output [XLEN-1:0] rd1, rd2 // src registers
);

    reg [XLEN-1:0] rf [31:0]; // register file

    // output from src registers
    assign rd1 = (a1 == 0) ? 0 : rf[a1];
    assign rd2 = (a2 == 0) ? 0 : rf[a2];

    // write to dest register
    always @(posedge clk) begin
        if (we3) begin
            if (a3 != 0) begin
               rf[a3] <= di3;
            end
        end
    end

endmodule