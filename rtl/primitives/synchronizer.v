`ifndef __FILE_SYNCHRONIZER_V
`define __FILE_SYNCHRONIZER_V

(* dont_touch = "yes" *) module synchronizer #(
    parameter LEN    = 32,
    parameter STAGES = 2
) (
    input            clk,
    input            en,
    input  [LEN-1:0] dataIn,
    output [LEN-1:0] dataOut,
    output [LEN-1:0] rise,
    output [LEN-1:0] fall
);
    
    reg [LEN-1:0] buffer [STAGES-1:0];
    integer i;

    always @(posedge clk) begin
        if (en) begin
            buffer[0] <= dataIn;

            for (i = 1; i < STAGES; i = i + 1) begin
                buffer[i] <= buffer[i - 1];
            end
        end
    end
    generate
        if (STAGES >= 2) begin
            assign rise = ~buffer[STAGES-2]  &  buffer[STAGES-1];
            assign fall =  buffer[STAGES-2]  & ~buffer[STAGES-1];
        end else begin
            assign rise = 0;
            assign fall = 0;
        end
    endgenerate

    assign dataOut = buffer[STAGES - 1];

endmodule

`endif // __FILE_SYNCHRONIZER_V