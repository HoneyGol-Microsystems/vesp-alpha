
module uart_datapath #(
    parameter RX_QUEUE_SIZE = 16,
    parameter TX_QUEUE_SIZE = 16
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        we,
    input  logic        re,
    input  logic [2:0]  regsel,
    input  logic [31:0] din,
    input  logic        tx_queue_re,
    input  logic        tx_shift_reg_we,
    input  logic        tx_shift_reg_se,
    input  logic        tx_bits_cnt_en,
    input  logic        tx_bits_cnt_reset,
    input  logic        tx_parity_we,
    input  logic        tx_parity_reset,
    input  logic        tx_out_sel,

    output logic [31:0] dout,
    output logic        tx,
    output logic        bit_clk_cnt_top,
    output logic        tx_queue_empty,
    output logic        tx_bits_cnt_top
);

    /////////////////////////////////////////////////////////////////////////
    // SIGNAL DECLARATIONS
    /////////////////////////////////////////////////////////////////////////
    logic [7:0] tx_queue_din, tx_queue_dout, rx_queue_din, rx_queue_dout,
                tx_shift_reg;
    logic       tx_queue_we, tx_shift_reg_lsb, tx_parity_out, ref_clk_cnt_top,
                sample_clk_cnt_top;

    /////////////////////////////////////////////////////////////////////////
    // SIGNAL ASSIGNMENTS
    /////////////////////////////////////////////////////////////////////////
    assign tx_shift_reg_lsb = tx_shift_reg[0];
    assign tx_queue_we      = re && we && (regsel == 3'h0);

    /////////////////////////////////////////////////////////////////////////
    // CONFIG/STATUS REGISTERS
    /////////////////////////////////////////////////////////////////////////
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

    /////////////////////////////////////////////////////////////////////////
    // REGISTER INTERFACE
    /////////////////////////////////////////////////////////////////////////
    // data in
    always_ff @(posedge clk) begin : register_write_proc
        if (we) begin
            case (regsel)
                3'h0:    tx_queue_din <= din[7:0];
                3'h2:    config_a     <= din[23:16];
                3'h3:    config_b     <= din[31:24];
                default: begin end
            endcase
        end
    end

    // data out 
    always_comb begin : register_read_proc
        case ( regsel )
            3'h0:    dout = { {24{1'b0}}, tx_queue_dout             };
            3'h1:    dout = { {16{1'b0}}, rx_queue_dout, { 8{1'b0}} };
            3'h2:    dout = { { 8{1'b0}}, config_a     , {16{1'b0}} };
            3'h3:    dout = { config_b  , {24{1'b0}}                };
            default: dout = { {16{1'b0}}, status_a     , { 8{1'b0}} };
        endcase
    end

    /////////////////////////////////////////////////////////////////////////
    // CLOCK ENABLE SIGNALS
    /////////////////////////////////////////////////////////////////////////
    // Reference clock. Generates 3.5714 MHz from 50 MHz system clock.
    counter #(
        .COUNTER_LENGTH(5)
    ) ref_clk_cnt (
        .reset(reset),
        .clk(clk),
        .en(1'b1),
        .max(13),
        .top(ref_clk_cnt_top)
    );

    // Main clock - used for RX sampling. Configurable.
    counter #(
        .COUNTER_LENGTH(5)
    ) sample_clk_cnt (
        .reset(reset),
        .clk(clk),
        .en(ref_clk_cnt_top),
        .max(config_a.clock_divisor),
        .top(sample_clk_cnt_top)
    );

    counter #(
        .COUNTER_LENGTH(4)
    ) bit_clk_cnt (
        .reset(reset),
        .clk(clk),
        .en(sample_clk_cnt_top),
        .max(15),
        .top(bit_clk_cnt_top)
    );

    counter #(
        .COUNTER_LENGTH(4)
    ) tx_bits_cnt (
        .reset(tx_bits_cnt_reset),
        .clk(clk),
        .en(tx_bits_cnt_en),
        .max(config_a.data_bits_count + 5),
        .top(tx_bits_cnt_top)
    );

    /////////////////////////////////////////////////////////////////////////
    // QUEUES
    /////////////////////////////////////////////////////////////////////////
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


    /////////////////////////////////////////////////////////////////////////
    // TX SHIFT REGISTER
    /////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin : tx_shift_reg_proc
        if (tx_shift_reg_we) begin
            tx_shift_reg <= tx_queue_dout;
        end else if (tx_shift_reg_se) begin
            tx_shift_reg[6:0] <= tx_shift_reg[7:1];
        end
    end

    /////////////////////////////////////////////////////////////////////////
    // TX PARITY
    /////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin : tx_parity_proc
        if (tx_parity_reset) begin
            tx_parity_out <= config_b.parity_type[1];
        end else if (tx_parity_we) begin
            tx_parity_out <= tx_shift_reg_lsb ? ~tx_parity_out : tx_parity_out;
        end
    end

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