
module uart_datapath #(
    parameter DATA_WIDTH    = 32,
    parameter RX_QUEUE_SIZE = 16,
    parameter TX_QUEUE_SIZE = 16
) (
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  tx_queue_we,
    input  logic                  tx_queue_re,
    input  logic [DATA_WIDTH-1:0] tx_queue_din,
    input  logic                  tx_shift_reg_we,
    input  logic                  tx_shift_reg_se,
    input  logic                  tx_bits_cnt_en,
    input  logic                  tx_bits_cnt_reset,
    input  logic                  tx_parity_we,
    input  logic                  tx_parity_reset,
    input  logic                  tx_out_sel,

    output logic                  tx,
    output logic                  bit_clk_cnt_top,
    output logic                  tx_queue_empty,
    output logic                  tx_bits_cnt_top
);

    //////////////////////////////////////////////////
    // SIGNAL DECLARATIONS
    //////////////////////////////////////////////////
    logic [DATA_WIDTH-1:0] tx_queue_dout;
    logic [DATA_WIDTH-1:0] tx_shift_reg;
    logic                  tx_shift_reg_lsb;
    logic                  tx_parity_out;

    //////////////////////////////////////////////////
    // SIGNAL ASSIGNMENTS
    //////////////////////////////////////////////////
    assign tx_shift_reg_lsb = tx_shift_reg[0];

    //////////////////////////////////////////////////
    // CONFIG/STATUS REGISTERS
    //////////////////////////////////////////////////
    // Config register A.
    struct packed {
        logic [4:0] clock_divisor;
        logic       irq_en_tx_empty;
        logic       irq_en_rx_full;
        logic       reserved;
    } config_a;

    // Config register B.
    struct packed {
        logic [1:0] parity_type;
        logic [1:0] data_bits_count;
        logic       double_stop_bits;
        logic [2:0] reserved;
    } config_b;
    
    // Status register A.
    struct packed {
        logic       tx_queue_full;
        logic       rx_queue_empty;
        logic [5:0] reserved;
    } status_a;

    //////////////////////////////////////////////////
    // CLOCK ENABLE SIGNALS
    //////////////////////////////////////////////////
    // TODO

    //////////////////////////////////////////////////
    // QUEUES
    //////////////////////////////////////////////////
    fifo #(
        .XLEN(8),
        .LENGTH(TX_QUEUE_SIZE)
    ) tx_queue (
        .clk(clk),
        .reset(reset),
        .we(tx_queue_we),
        .re(tx_queue_re),
        .di(tx_queue_din),
        .empty(tx_queue_empty),
        .full(status_a.tx_queue_full),
        .dout(tx_queue_dout)
    );


    //////////////////////////////////////////////////
    // TX SHIFT REGISTER
    //////////////////////////////////////////////////
    always_ff @(posedge clk) begin : tx_shift_reg_proc
        if (tx_shift_reg_we) begin
            tx_shift_reg <= tx_queue_dout;
        end else if (tx_shift_reg_se) begin
            tx_shift_reg[DATA_WIDTH-2:0] <= tx_shift_reg[DATA_WIDTH-1:1];
        end
    end

    //////////////////////////////////////////////////
    // TX PARITY
    //////////////////////////////////////////////////
    always_ff @(posedge clk) begin : tx_parity_proc
        if (tx_parity_reset) begin
            tx_parity_out <= config_b.parity_type[1];
        end else if (tx_parity_we) begin
            tx_parity_out <= tx_shift_reg_lsb ? ~tx_parity_out : tx_parity_out;
        end
    end

    //////////////////////////////////////////////////
    // TX OUTPUT MULTIPLEXER
    //////////////////////////////////////////////////
    always_comb begin : tx_out_sel_mux_proc
        case (tx_out_sel)
            2'b00:   tx = 0;
            2'b01:   tx = 1;
            2'b10:   tx = tx_shift_reg_lsb;
            default: tx = tx_parity_out;
        endcase
    end

endmodule