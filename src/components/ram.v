// Dual port RAM.
module ram(
    // Addresses.
    input [31:0] a1, a2,
    // Data inputs and outputs.
    input [31:0] do1, di2, do2,
    // Data mask selection.
    input [3:0] m2,
    // Write enable.
    input we2,
    input clk
);

    reg [31:0] RAM [127:0]

    assign do1 = RAM[a1[31:2]]
    assign do2 = RAM[a2[31:2]]

    always @(posedge clk) begin
        if(we2) begin
            if (m2[0]) begin
                RAM[a2[31:2]][7:0] <= di2[7:0];
            end

            if (m2[1]) begin
                RAM[a2[31:2]][15:8] <= di2[15:8];
            end

            if (m2[2]) begin
                RAM[a2[31:2]][23:16] <= di2[23:16];
            end

            if (m2[3]) begin
                RAM[a2[31:2]][31:24] <= di2[31:24];
            end
        end
    end

endmodule