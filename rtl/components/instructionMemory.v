`ifndef __FILE_INSTRUCTION_MEMORY_V
`define __FILE_INSTRUCTION_MEMORY_V

module instructionMemory #(
    parameter WORD_CNT = 16 // number of words (32b) in memory
) (
    input  [31:0] a,
    output [31:0] d
);

    reg [31:0] ram [WORD_CNT-1:0];

    assign d = ram[a[31:2]];

endmodule

`endif // __FILE_INSTRUCTION_MEMORY_V