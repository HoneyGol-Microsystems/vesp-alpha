module dataMemory (
    input         clk,
    input         reset,
    input         we,
    input  [3:0]  mask,
    input  [31:0] a,
    input  [31:0] di,
    output [31:0] do
);

    reg [31:0] ram [63:0];

    initial begin
        $readmemh("data.hex", ram, 0, 63);
    end

    assign do = ram[a[31:2]];

    always @(posedge clk) begin
        if (we) begin
            if (mask[0]) begin
                ram[a[31:2]][7:0] <= di[7:0];
            end

            if (mask[1]) begin
                ram[a[31:2]][15:8] <= di[15:8];
            end

            if (mask[2]) begin
                ram[a[31:2]][23:16] <= di[23:16];
            end

            if (mask[3]) begin
                ram[a[31:2]][31:24] <= di[31:24];
            end
        end
    end

endmodule