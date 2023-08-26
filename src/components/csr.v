`ifndef __FILE_CSR_V
`define __FILE_CSR_V

module csr (
    input reset,
    input clk,
    input we,
    input [11:0] a,
    input [31:0] di,
    output reg [31:0] do,

    output [31:0] mepcDo,
    output [31:0] mtvecDo,
    output [31:0] mcauseDo,

    input  mepcWe,
    input  mcauseWe,

    input  [31:0] mepcDi,
    input  [31:0] mcauseDi
);

    // ====== Machine Trap Setup ======
    // Machine Cause Register
    reg [31:0]  mcause;

    // Machine Trap Handling.
    reg [31:0] mepc, mtvec;

    // ====== Direct register reads ======
    assign mepcDo       = mepc;
    assign mtvecDo      = mtvec;
    assign mcauseDo     = mcause;

    // ====== Main I/O register reads ======
    always @(*) begin
        
        case (a)

            // misa :)
            'h301:  do = 'b10000000000000000000000100000000;
            'h305:  do = mtvec;
            'h341:  do = mepc;
            'h342:  do = mcause;

            default: do = 0;
        endcase
    end

    // ====== Main I/O + direct register writes ======
    // All drivers should be in a single always block.
    always @(posedge clk) begin
        
        if (reset) begin

            mtvec   = 0;
            mepc    = 0;
            mcause  = 0;

        end else begin
            
            if (we) begin
 
                case (a)
                    // Permit MODE only 0, 1 (direct, vectored).
                    'h305: mtvec    = {di[31:2], di[1:0] < 2 ? di[1:0] : mtvec[1:0]};
                    'h341: mepc     = di;                
                endcase

            end

            // Direct writes have priority.
            if (mepcWe)     mepc   = mepcDi;
            if (mcauseWe)   mcause = mcauseDi;
        end
    end

endmodule

`endif //__FILE_CSR_V