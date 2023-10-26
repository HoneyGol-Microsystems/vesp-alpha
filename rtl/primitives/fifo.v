module fifo #(
    parameter XLEN    = 32,
    parameter LENGTH  = 16
) (
    input                 clk,
    input                 reset,
    input                 we,
    input                 re,
    input  [XLEN-1:0]     di,
    output reg            empty,
    output reg            full,
    output [XLEN-1:0]     do
);

reg [$clog2(LENGTH) - 1:0] frontPointer, backPointer;
reg [XLEN-1:0] memory [LENGTH-1:0];

always @( posedge clk ) begin
    
    if ( reset ) begin
        frontPointer = 0;
        backPointer  = 0;
        empty        = 1;
        full         = 0;
    end else begin
        
        if ( we && !full ) begin
            memory[backPointer] = di;
            backPointer += 1;
            empty = 0;
            if ( frontPointer == backPointer ) begin
                full = 1;
            end
        end

        if ( re && !empty ) begin
            frontPointer += 1;
            full = 0;
            if ( frontPointer == backPointer ) begin
                empty = 1;
            end
        end
    end
end

assign do = memory[frontPointer];

endmodule