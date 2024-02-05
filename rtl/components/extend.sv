`ifndef __FILE_EXTEND_V
`define __FILE_EXTEND_V

(* dont_touch = "yes" *) module module_extend #(
    parameter DATA_LEN = 8, // width of data
    parameter RES_LEN  = 32 // width of result (extended) data
) (
    input  logic [DATA_LEN-1:0] data, // data to be extended
    input  logic                uext, // whether to perform unsigned extension

    output logic [RES_LEN-1:0]  res   // result (extended data)
);

    assign res = uext ? { {(RES_LEN - DATA_LEN){!uext}}, data } : { {(RES_LEN - DATA_LEN){data[DATA_LEN-1]}}, data };

endmodule

`endif // __FILE_EXTEND_V