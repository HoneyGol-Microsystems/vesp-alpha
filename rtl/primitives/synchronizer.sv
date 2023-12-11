`ifndef __FILE_SYNCHRONIZER_V
`define __FILE_SYNCHRONIZER_V

(* dont_touch = "yes" *) module synchronizer #(
    parameter LEN    = 32,
    parameter STAGES = 2    // At least 2 required.
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

            // There is additional one stage for rise/fall detection to work!
            // See scheme for reference.
            for (i = 1; i < STAGES + 1; i = i + 1) begin
                buffer[i] <= buffer[i - 1];
            end
        end
    end
    generate
        if (STAGES >= 2) begin
            assign rise =  buffer[STAGES - 2]  & ~buffer[STAGES - 1];
            assign fall = ~buffer[STAGES - 2]  &  buffer[STAGES - 1];
        end else begin
            $fatal("There must be at least two stages! (STAGES parameter error.)");
        end
    endgenerate

    assign dataOut = buffer[STAGES - 2];

endmodule

`endif // __FILE_SYNCHRONIZER_V