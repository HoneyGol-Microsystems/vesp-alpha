`ifndef __FILE_ADDRESSDECODER_V
`define __FILE_ADDRESSDECODER_V

(* dont_touch = "yes" *) module addressDecoder (
    input             we,
    input      [31:0] a,
    output reg [2:0]  outsel,
    output reg        wemem,
    output reg        wegpio
    // output reg        weuart0,
    // output reg        wepwm,
    // output reg        wetmr0
);

    always @(*) begin
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