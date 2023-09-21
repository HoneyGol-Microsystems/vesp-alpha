`ifndef __FILE_INSTRUCTION_MEMORY_V
`define __FILE_INSTRUCTION_MEMORY_V

`include "src/constants.vh"

module instructionMemory #(
    parameter WORD_CNT = 16, // number of words (32b) in memory
    parameter MEM_DATA = "text.hex"
) (
    input  [31:0] a,
    output [31:0] d
);

    reg [31:0] ram [WORD_CNT-1:0];

    initial begin
        $readmemh(MEM_DATA, ram, 0, `INSTR_MEM_WORD_CNT-1);
    end

    assign d = ram[a[31:2]];

endmodule

`endif // __FILE_INSTRUCTION_MEMORY_V