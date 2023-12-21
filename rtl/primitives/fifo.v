(* dont_touch = "yes" *) module fifo #(
    parameter XLEN    = 32,
    parameter LENGTH  = 16
) (
    input                 clk,
    input                 reset,
    input                 we,
    input                 re,
    input  [XLEN-1:0]     din,
    output reg            empty,
    output reg            full,
    output [XLEN-1:0]     dout
);

reg  [$clog2(LENGTH) - 1:0] frontPointer, backPointer;
reg  [XLEN-1:0]             memory [LENGTH-1:0];

wire [$clog2(LENGTH) - 1:0] frontPointerInc, backPointerInc;

always @( posedge clk ) begin : fifo_operations
    
    if ( reset ) begin

        frontPointer <= 0;
        backPointer  <= 0;
        empty        <= 1;
        full         <= 0;

    end else begin        

        if ( we && !full ) begin
            memory[backPointer] <= din;
            backPointer         <= backPointerInc;

            empty <= 0;
            if ( !re ) begin
                full  <= ( frontPointer == backPointerInc ) ? 1'b1 : 1'b0;
            end
        end

        if ( re && !empty ) begin
            frontPointer <= frontPointerInc;

            if ( !we ) begin
                empty <= ( frontPointerInc == backPointer ) ? 1'b1 : 1'b0;
                full  <= 0;
            end
        end
    end
end

assign dout = memory[frontPointer];

// Incrementation needs to be separated to keep correct width when comparing.
assign frontPointerInc = frontPointer + 1;
assign backPointerInc  = backPointer  + 1;

endmodule