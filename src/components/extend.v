module extend #(
    parameter DATA_LEN = 8, // width of data
    parameter RES_LEN = 32  // width of result (extended) data
) (
    input [DATA_LEN-1:0] data, // data to be extended
    input uext,                // whether to perform unsigned extension
    output [RES_LEN-1:0] res   // result (extended data)
);

    assign res = { {(RES_LEN - DATA_LEN){!uext}}, data };

endmodule