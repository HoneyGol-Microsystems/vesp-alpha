module cpu (
    input         clk,
    input         reset,
    input  [31:0] instruction,
    input  [31:0] data_from_mem,
    output        WE, // write enable to data memory
    output        ex, // exception TODO: type of exception
    output [31:0] PC,
    output [31:0] mem_addr,
    output [31:0] data_to_mem
);

endmodule