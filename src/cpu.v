module cpu (
    input         clk,
    input         reset,
    input  [31:0] instruction,
    input  [31:0] dataFromMem,
    output        WE,     // write enable to data memory
    output        except, // exception TODO: type of exception
    output [31:0] PC,
    output [31:0] memAddr,
    output [31:0] dataToMem
);

endmodule