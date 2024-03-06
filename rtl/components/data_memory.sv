`ifndef __FILE_DATA_MEMORY_V
`define __FILE_DATA_MEMORY_V

(* dont_touch = "yes" *) module module_data_memory #(
    parameter WORD_CNT = 16, // number of words (32b) in memory
    parameter MEM_FILE = ""
) (
    input  logic        clk,
    input  logic        we,
    input  logic [3:0]  mask,
    input  logic [31:0] a,
    input  logic [31:0] din,

    output logic [31:0] dout
);

    logic [31:0] ram [WORD_CNT-1:0];

    initial begin
        if (MEM_FILE != "") begin
            $readmemh(MEM_FILE, ram, 0, WORD_CNT-1);
        end
    end

    assign dout = ram[a[31:2]];

    always_ff @(posedge clk) begin
        if (we) begin
            if (mask[0]) begin
                ram[a[31:2]][7:0] <= din[7:0];
            end

            if (mask[1]) begin
                ram[a[31:2]][15:8] <= din[15:8];
            end

            if (mask[2]) begin
                ram[a[31:2]][23:16] <= din[23:16];
            end

            if (mask[3]) begin
                ram[a[31:2]][31:24] <= din[31:24];
            end
        end
    end

endmodule

`endif // __FILE_DATA_MEMORY_V