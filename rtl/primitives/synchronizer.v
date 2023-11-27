`ifndef __FILE_SYNCHRONIZER_V
`define __FILE_SYNCHRONIZER_V

(* dont_touch = "yes" *) module synchronizer #(
    parameter LEN    = 32,
    parameter STAGES = 2
) (
    input            clk,
    input  [LEN-1:0] dataIn,
    output [LEN-1:0] dataOut
);
    
    reg [LEN-1:0] buffer [STAGES-1:0];
    integer i;

    always @(posedge clk) begin
        
        buffer[0] <= dataIn;
        
        for (i = 1; i < STAGES; i = i + 1) begin
            buffer[i] <= buffer[i - 1];
        end
    end

    assign dataOut = buffer[STAGES - 1];

endmodule

`endif // __FILE_SYNCHRONIZER_V