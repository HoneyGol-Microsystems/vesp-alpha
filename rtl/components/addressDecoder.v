`ifndef __FILE_ADDRESSDECODER_V
`define __FILE_ADDRESSDECODER_V

(* dont_touch = "yes" *) module addressDecoder (
    input             we,
    input      [31:0] a,
    output reg [2:0]  outsel,
    output reg        wemem,
    output reg        wegpio,
    output reg        reuart0,
    output reg        weuart0
    // output reg        wepwm,
    // output reg        wetmr0
);

    always @(*) begin
        outsel  = 0;
        wemem   = 0;
        wegpio  = 0;
        weuart0 = 0;
        reuart0 = 0;
        // wepwm   = 0;
        // wetmr0  = 0;

        if (a < 32'hF000_0000) begin
            wemem   = we;
            outsel  = 3'b000;
        end else if (a < 32'hF000_0006) begin
            wegpio  = we;
            outsel  = 3'b001;
        end else if (a > 32'hF000_000F && a < 32'hF000_0018) begin
            weuart0 = we;
            reuart0 = !we;
            outsel  = 3'b010;
        end else begin
            // Nothing connected. Throw an exception?
        end
    end

endmodule

`endif // __FILE_ADDRESSDECODER_V