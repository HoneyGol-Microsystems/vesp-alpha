
(* dont_touch = "yes" *) module uart_tx_datapath #(
    parameter TX_QUEUE_SIZE = 16
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       tx_queue_we,
    input  logic       tx_queue_re,
    input  logic [7:0] tx_queue_din,
    input  logic       tx_shift_reg_we,
    input  logic       tx_shift_reg_se,
    input  logic       tx_shift_reg_reset,
    input  logic [1:0] tx_out_sel,
    input  logic       tx_bits_cnt_en,
    input  logic       tx_bits_cnt_reset,
    input  logic [1:0] data_bits_count,
    input  logic       parity_type,
    input  logic       tx_parity_we,
    input  logic       tx_parity_reset,

    output logic       tx,
    output logic       tx_queue_empty,
    output logic       tx_queue_full,
    output logic       tx_bits_cnt_top
);

    /////////////////////////////////////////////////////////////////////////
    // SIGNAL DECLARATIONS
    /////////////////////////////////////////////////////////////////////////
    logic tx_shift_reg_lsb, tx_parity_out;
    logic [7:0] tx_shift_reg, tx_queue_dout;
    logic [4:0] tx_bits_cnt_max;

    /////////////////////////////////////////////////////////////////////////
    // SIGNAL ASSIGNMENTS
    /////////////////////////////////////////////////////////////////////////
    assign tx_shift_reg_lsb = tx_shift_reg[0];
    assign tx_bits_cnt_max  = data_bits_count + 3'h5;
    
    /////////////////////////////////////////////////////////////////////////
    // TX QUEUE
    /////////////////////////////////////////////////////////////////////////
    fifo #(
        .XLEN(8),
        .LENGTH(TX_QUEUE_SIZE)
    ) tx_queue (
        .clk(clk),
        .reset(reset),
        .we(tx_queue_we),
        .re(tx_queue_re),
        .din(tx_queue_din),
        .empty(tx_queue_empty),
        .full(tx_queue_full),
        .dout(tx_queue_dout)
    );

    /////////////////////////////////////////////////////////////////////////
    // TX SHIFT REGISTER
    /////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin : tx_shift_reg_proc
        if (tx_shift_reg_reset) begin
            tx_shift_reg <= 0;
        end else if (tx_shift_reg_we) begin
            tx_shift_reg <= tx_queue_dout;
        end else if (tx_shift_reg_se) begin
            tx_shift_reg[6:0] <= tx_shift_reg[7:1];
        end
    end

    /////////////////////////////////////////////////////////////////////////
    // TX BITS SENT COUNTER
    /////////////////////////////////////////////////////////////////////////
    counter #(
        .COUNTER_WIDTH(5)
    ) tx_bits_cnt (
        .reset(tx_bits_cnt_reset),
        .clk(clk),
        .en(tx_bits_cnt_en),
        .max(tx_bits_cnt_max),
        .top(tx_bits_cnt_top)
    );

    /////////////////////////////////////////////////////////////////////////
    // TX SERIAL PARITY CALCULATOR
    /////////////////////////////////////////////////////////////////////////
    parity_serial_calculator tx_parity (
        .clk(clk),
        .reset(tx_parity_reset),
        .din(tx_shift_reg_lsb),
        .we(tx_parity_we),
        .odd(parity_type),
        .parity(tx_parity_out)
    );

    /////////////////////////////////////////////////////////////////////////
    // TX OUTPUT MULTIPLEXER
    /////////////////////////////////////////////////////////////////////////
    always_comb begin : tx_out_sel_mux_proc
        case (tx_out_sel)
            2'b00:   tx = 0;
            2'b01:   tx = 1;
            2'b10:   tx = tx_shift_reg_lsb;
            default: tx = tx_parity_out;
        endcase
    end

endmodule