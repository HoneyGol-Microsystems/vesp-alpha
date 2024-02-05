`ifndef __FILE_INSTRUCTION_MEMORY_V
`define __FILE_INSTRUCTION_MEMORY_V

(* dont_touch = "yes" *) module module_instruction_memory #(
    parameter WORD_CNT = 16, // number of words (32b) in memory
    parameter MEM_FILE = ""
) (
    input  [31:0] a,

    output [31:0] d
);

    logic [31:0] ram [WORD_CNT-1:0];

    initial begin
        if (MEM_FILE != "") begin
            $readmemh(MEM_FILE, ram, 0, WORD_CNT-1);
        end
    end

    assign d = ram[a[31:2]];

endmodule

`endif // __FILE_INSTRUCTION_MEMORY_V