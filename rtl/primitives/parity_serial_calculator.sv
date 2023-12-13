
module parity_serial_calculator (
    input  logic clk,
    input  logic reset,
    input  logic din,
    input  logic we,
    input  logic odd,
    output logic parity
);

    logic parity_tmp;
    assign parity = parity_tmp;
    
    always_ff @(posedge clk) begin : parity_calculate_proc
        if (reset) begin
            parity_tmp <= odd;
        end else if (we) begin
            parity_tmp <= din ? ~parity_tmp : parity_tmp;
        end
    end

endmodule