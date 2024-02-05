`ifndef __FILE_SYNCHRONIZER_V
`define __FILE_SYNCHRONIZER_V

(* dont_touch = "yes" *) module module_synchronizer #(
    parameter LEN    = 32,
    parameter STAGES = 2    // At least 2 required.
) (
    input  logic           clk,
    input  logic           en,
    input  logic [LEN-1:0] data_in,

    output logic [LEN-1:0] data_out,
    output logic [LEN-1:0] rise,
    output logic [LEN-1:0] fall
);
    
    // There is additional one stage for rise/fall detection to work!
    // See scheme for reference.
    logic [LEN-1:0] buffer [STAGES:0];
    integer i;

    always_ff @(posedge clk) begin
        if (en) begin
            buffer[0] <= data_in;

            for (i = 1; i < STAGES + 1; i = i + 1) begin
                buffer[i] <= buffer[i - 1];
            end
        end
    end
    
    generate
        if (STAGES >= 2) begin
            assign rise =  buffer[STAGES - 1]  & ~buffer[STAGES];
            assign fall = ~buffer[STAGES - 1]  &  buffer[STAGES];
        end else begin
            $fatal("There must be at least two stages! (STAGES parameter error.)");
        end
    endgenerate

    assign data_out = buffer[STAGES - 1];

endmodule

`endif // __FILE_SYNCHRONIZER_V