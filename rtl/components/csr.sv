`ifndef __FILE_CSR_V
`define __FILE_CSR_V

(* dont_touch = "yes" *) module module_csr (
    input  logic        clk,
    input  logic        reset,
    input  logic        we,
    input  logic        mepc_we,
    input  logic        mcause_we,
    input  logic [11:0] a,
    input  logic [31:0] din,
    input  logic [31:0] mepc_din,
    input  logic [31:0] mcause_din,

    output logic [31:0] dout,
    output logic [31:0] mepc_dout,
    output logic [31:0] mtvec_dout,
    output logic [31:0] mcause_dout
);

    // ====== Machine Trap Setup ======
    // Machine Cause Register
    logic [31:0] mcause;

    // Machine Trap Handling.
    logic [31:0] mepc, mtvec;

    // ====== Machine Trap Handling ======
    logic [31:0] mscratch;

    // ====== Direct register reads ======
    assign mepc_dout   = mepc;
    assign mtvec_dout  = mtvec;
    assign mcause_dout = mcause;

    // ====== Main I/O register reads ======
    always_comb begin
        case (a)
            // misa :)
            'h301:   dout = 'b01000000000000000000000100000000;
            'h305:   dout = mtvec;
            'h340:   dout = mscratch;
            'h341:   dout = mepc;
            'h342:   dout = mcause;
            default: dout = 0;
        endcase
    end

    // ====== Main I/O + direct register writes ======
    // All drivers should be in a single always block.
    always_ff @(posedge clk) begin
        if (reset) begin
            mtvec    = 0;
            mepc     = 0;
            mcause   = 0;
            mscratch = 0;
        end else begin
            if (we) begin
                case (a)
                    // Permit MODE only 0, 1 (direct, vectored).
                    'h305: mtvec    = {din[31:2], din[1:0] < 2 ? din[1:0] : mtvec[1:0]};
                    'h340: mscratch = din;
                    'h341: mepc     = din;
                endcase
            end

            // Direct writes have priority.
            if (mepc_we)   mepc   = mepc_din;
            if (mcause_we) mcause = mcause_din;
        end
    end

endmodule

`endif //__FILE_CSR_V