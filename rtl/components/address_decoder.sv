`ifndef __FILE_ADDRESSDECODER_V
`define __FILE_ADDRESSDECODER_V

(* dont_touch = "yes" *) module module_address_decoder (
    input  logic        we,
    input  logic [31:0] a,

    output logic [2:0]  outsel,
    output logic        wemem,
    output logic        wegpio
    // output logic        weuart0,
    // output logic        wepwm,
    // output logic        wetmr0
);

    always_comb begin
        wemem   = 0;
        wegpio  = 0;
        outsel  = 0;
        // weuart0 = 0;
        // wepwm   = 0;
        // wetmr0  = 0;

        if (a < 32'hF000_0000) begin
            wemem   = we;
            outsel  = 3'b000;
        end else if (a < 32'hF000_0006) begin
            wegpio  = we;
            outsel  = 3'b001;
        end else if (a == 32'hF000_0020) begin
            outsel  = 3'b011;
        end else begin
            // Nothing connected. Throw an exception?
        end
    end

endmodule

`endif // __FILE_ADDRESSDECODER_V