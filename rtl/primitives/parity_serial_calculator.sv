
module parity_serial_calculator (
    input  logic clk,
    input  logic reset,
    input  logic din,
    input  logic we,
    input  logic odd,
    output logic parity
);

    always_ff @(posedge clk) begin : parity_calculate_proc
        if (reset) begin
            parity <= odd;
        end else if (we) begin
            parity <= din ? ~parity : parity;
        end
    end

endmodule