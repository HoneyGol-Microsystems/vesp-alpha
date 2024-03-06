`ifndef __FILE_RAM_V
`define __FILE_RAM_V

// Dual port RAM.
(* dont_touch = "yes" *) module module_ram #(
    parameter WORD_CNT = 16, // number of words (32b) in RAM
    parameter MEM_FILE = ""
) (
    input  logic        clk,
    input  logic [31:0] a1, a2,
    input  logic [31:0] di2,
    input  logic [3:0]  m2, // Data mask selection.
    input  logic        we2,

    output logic [31:0] do1, do2
);

    (*rom_style = "block"*) logic [31:0] ram [WORD_CNT-1:0];

    initial begin
        if (MEM_FILE != "") begin
            $readmemh(MEM_FILE, ram, 0, WORD_CNT-1);
        end
    end

    assign do1 = ram[a1[31:2]];
    assign do2 = ram[a2[31:2]];

    always_ff @(posedge clk) begin
        if (we2) begin
            if (m2[0]) begin
                ram[a2[31:2]][7:0] <= di2[7:0];
            end

            if (m2[1]) begin
                ram[a2[31:2]][15:8] <= di2[15:8];
            end

            if (m2[2]) begin
                ram[a2[31:2]][23:16] <= di2[23:16];
            end

            if (m2[3]) begin
                ram[a2[31:2]][31:24] <= di2[31:24];
            end
        end    
    end

endmodule

`endif // __FILE_RAM_V