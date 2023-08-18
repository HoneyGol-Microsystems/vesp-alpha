`ifndef __FILE_LEDDEBUGTOP_V
`define __FILE_LEDDEBUGTOP_V

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/15/2023 05:57:31 PM
// Design Name: 
// Module Name: ledDebugTop
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "src/components/top.v"

module ledDebugTop(
    input sysClk,
    input sysRes,
    output [31:16] PCdebug
);

    top topInst(
        .sysClk(sysClk),
        .sysRes(sysRes)
    );
    
    assign PCdebug = topInst.cpu.PC[31:16];

endmodule

`endif // __FILE_LEDDEBUGTOP_V