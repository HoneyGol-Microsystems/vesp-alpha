module fifo #(
    parameter XLEN    = 32,
    parameter LENGTH  = 16
) (
    input                 clk,
    input                 reset,
    input                 we,
    input                 re,
    input  [XLEN-1:0]     di,
    output                empty,
    output                full,
    output [XLEN-1:0]     do
);

reg [$clog2(LENGTH) - 1:0] frontPointer, backPointer;
reg [XLEN-1:0] memory [LENGTH-1:0];
reg lastWrite, lastRead;

always @( posedge clk ) begin
    
    if ( reset ) begin
        frontPointer <= 0;
        backPointer  <= 0;
        empty        <= 1;
        full         <= 0;
    end else begin
        
        if ( we && !full ) begin
            memory[backPointer] <= di;
            backPointer <= backPointerInc;
            empty <= 0;
            if ( frontPointer == backPointerInc ) begin
                full <= 1;
            end
        end else if ( re && !empty ) begin
            frontPointer <= frontPointerInc;
            full <= 0;
            if ( frontPointerInc == backPointer ) begin
                empty <= 1;
            end
        end
    end
end

always @( * ) begin : fifo_status

    if ( lastWrite && !lastRead ) begin
        empty = 0;
    end else if ( !lastWrite && lastRead ) begin
        
    end else begin
        
    end
end

always @( posedge clk ) begin : fifo_operations
    
    if ( reset ) begin
        frontPointer <= 0;
        backPointer  <= 0;
        lastWrite    <= 0;
        lastRead     <= 0;
    end else begin        
        if ( we && !full ) begin
            memory[backPointer] <= di;
            backPointer <= backPointer + 1;
            lastWrite   <= 1;
        end else begin
            lastWrite <= 0;
        end

        if ( re && !empty ) begin
            frontPointer <= frontPointer + 1;
            lastRead     <= 1;
        end else begin
            lastRead <= 0;
        end
    end
end

assign do    = memory[frontPointer];

endmodule