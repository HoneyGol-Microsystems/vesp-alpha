module instructionMemory (
    input  [5:0]  a,
    output [31:0] d
);

    reg [31:0] ram [63:0];

    assign d = ram[a];

    initial begin
        $readmemh("inst.hex", ram, 0, 63);
    end

endmodule