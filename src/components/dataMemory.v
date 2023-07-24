module dataMemory (
    input         clk,
    input         reset,
    input         we,
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
            ram[a[31:2]] <= di;
        end
    end

endmodule