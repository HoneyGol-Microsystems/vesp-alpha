`include "src/constants.vh"

/* Generic register file with GPR's */
module register_file #(
    parameter REG_CNT = 32, // number of registers
    parameter XLEN = `XLEN  // width of registers
) (
    input [$floor($sqrt(REG_CNT))-1:0] a1, a2, a3, // address to src (a1, a2) and dest (a3) register
    input di3, // data to write to dest register
    input we3, // write enable for dest register
    input clk, // clock
    output reg [XLEN-1:0] r1, r2 // src registers
);

    reg [XLEN-1:0] rf [REG_CNT-1:0]; // registers

    always @(posedge clk) begin
        // output from src registers
        if (a1 == 0) begin
            r1 <= 0;
        end else begin
            r1 <= rf[a1];
        end
        if (a2 == 0) begin
            r2 <= 0;
        end else begin
            r2 <= rf[a2];
        end

        // write to dest register
        if (we3) begin
            if (a3 != 0) begin
               rf[a3] <= di3; 
            end
        end
    end

endmodule