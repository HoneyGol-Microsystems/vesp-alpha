
(* dont_touch = "yes" *) module module_uart_top #(
    parameter TX_QUEUE_SIZE = 16,
    parameter RX_QUEUE_SIZE = 16
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        rx,
    input  logic        re,
    input  logic        we,
    input  logic [2:0]  regsel,
    input  logic [31:0] din,

    output logic        tx,
    output logic        par_irq,
    output logic        stop_bit_irq,
    output logic [31:0] dout
);

    /////////////////////////////////////////////////////////////////////////
    // SIGNAL DECLARATIONS
    /////////////////////////////////////////////////////////////////////////
    logic stop_bit_error_if_en, parity_error_if_en, tx_queue_empty,
          rx_queue_full, rx_sync, rx_parity_out, if_reg_reset, ref_clk_cnt_top,
          sample_clk_cnt_top, rx_sync_fall, rx_get_sample, rx_bits_cnt_top,
          rx_error_reg_out, rx_sample_cnt_reset, rx_parity_we, rx_queue_we,
          rx_sample_reg_reset, rx_sample_reg_we, rx_parity_reset, tx_queue_re,
          rx_bits_cnt_reset, rx_bits_cnt_en, rx_error_reg_set, tx_bits_cnt_top,
          rx_error_reg_reset, tx_bits_cnt_reset, tx_bits_cnt_en, tx_queue_we,
          tx_shift_reg_we, tx_shift_reg_se, tx_parity_reset, tx_parity_we, 
          tx_send_bit;
    logic [1:0] tx_out_sel;
    logic [7:0] tx_queue_dout, rx_queue_dout;

    /////////////////////////////////////////////////////////////////////////
    // SIGNAL ASSIGNMENTS
    /////////////////////////////////////////////////////////////////////////
    assign if_reg_reset = (we && regsel == 3'h5);
    assign tx_queue_we  = (!re && we && regsel == 3'h0);

    /////////////////////////////////////////////////////////////////////////
    // CONFIG, STATUS AND INTERRUPT FLAG REGISTERS
    /////////////////////////////////////////////////////////////////////////
    // Config register A.
    struct packed {
        logic [4:0] clock_divisor;
        logic       tx_queue_empty_irq_en;
        logic       rx_queue_full_irq_en;
        logic       parity_error_irq_en;
    } config_a;

    // Config register B.
    struct packed {
        logic [1:0] parity_type;
        logic [1:0] data_bits_count;
        logic       double_stop_bits;
        logic       stop_bit_error_irq_en;
        logic [1:0] reserved;
    } config_b;
    
    // Status register A.
    struct packed {
        logic       tx_queue_full;
        logic       rx_queue_empty;
        logic [5:0] reserved;
    } status_a;

    // interrupt flag registers
    struct packed {
        logic       tx_queue_empty;
        logic       rx_queue_full;
        logic       parity_error;
        logic       stop_bit_error;
        logic [3:0] reserved;
    } if_reg;

    /////////////////////////////////////////////////////////////////////////
    // INTERRUPT FLAG REGISTERS RESET/WRITE
    /////////////////////////////////////////////////////////////////////////
    // TX queue empty IF register
    always_ff @(posedge clk) begin : tx_queue_empty_if_proc
        if (if_reg_reset) begin
            if_reg.tx_queue_empty <= if_reg.tx_queue_empty & din[16+7];
        end else if (config_a.tx_queue_empty_irq_en) begin
            if_reg.tx_queue_empty <= tx_queue_empty;
        end
    end

    // RX queue full IF register
    always_ff @(posedge clk) begin : rx_queue_full_if_proc
        if (if_reg_reset) begin
            if_reg.rx_queue_full <= if_reg.rx_queue_full & din[16+6];
        end else if (config_a.rx_queue_full_irq_en) begin
            if_reg.rx_queue_full <= rx_queue_full;
        end
    end

    // parity error IF register
    always_ff @(posedge clk) begin : parity_error_if_proc
        if (if_reg_reset) begin
            if_reg.parity_error <= if_reg.parity_error & din[16+5];
        end else if (config_a.parity_error_irq_en && parity_error_if_en) begin
            if_reg.parity_error <= rx_parity_out;
        end
    end

    // stop bit error IF register
    always_ff @(posedge clk) begin : stop_bit_error_if_proc
        if (if_reg_reset) begin
            if_reg.stop_bit_error <= if_reg.stop_bit_error & din[16+4];
        end else if (config_b.stop_bit_error_irq_en && stop_bit_error_if_en) begin
            if_reg.stop_bit_error <= !rx_sync;
        end
    end

    /////////////////////////////////////////////////////////////////////////
    // REGISTER INTERFACE
    /////////////////////////////////////////////////////////////////////////
    // data in
    always_ff @(posedge clk) begin : register_write_proc
        if (we) begin
            case (regsel)
                3'h2:    config_a <= din[23:16];
                3'h3:    config_b <= din[31:24];
                default: begin end
            endcase
        end
    end

    // data out 
    always_comb begin : register_read_proc
        case (regsel)
            3'h0:    dout = { {24{1'b0}}, tx_queue_dout             };
            3'h1:    dout = { {16{1'b0}}, rx_queue_dout, { 8{1'b0}} };
            3'h2:    dout = { { 8{1'b0}}, config_a     , {16{1'b0}} };
            3'h3:    dout = { config_b  , {24{1'b0}}                };
            3'h4:    dout = { {24{1'b0}}, status_a                  };
            default: dout = { {16{1'b0}}, if_reg       , {8{1'b0}}  };
        endcase
    end

    /////////////////////////////////////////////////////////////////////////
    // CLOCK ENABLE SIGNALS
    /////////////////////////////////////////////////////////////////////////
    // Reference clock. Generates 3.5714 MHz from 50 MHz system clock.
    counter #(
        .COUNTER_WIDTH(4)
    ) ref_clk_cnt (
        .reset(reset),
        .clk(clk),
        .en(1'b1),
        .max(13),
        .top_pulse(ref_clk_cnt_top)
    );

    // Main clock - used for RX sampling. Configurable.
    counter #(
        .COUNTER_WIDTH(5)
    ) sample_clk_cnt (
        .reset(reset),
        .clk(clk),
        .en(ref_clk_cnt_top),
        .max(config_a.clock_divisor),
        .top_pulse(sample_clk_cnt_top)
    );

    // bit clk counter
    counter #(
        .COUNTER_WIDTH(4)
    ) bit_clk_cnt (
        .reset(reset),
        .clk(clk),
        .en(sample_clk_cnt_top),
        .max(15),
        .top_pulse(tx_send_bit)
    );

    /////////////////////////////////////////////////////////////////////////
    // RX CONTROLLER
    /////////////////////////////////////////////////////////////////////////
    module_uart_rx_controller rx_ctrl (
        .clk(clk),
        .reset(reset),
        .parity_en(config_b.parity_type != 2'b0),
        .double_stop_bit(config_b.double_stop_bits),
        .rx_queue_full(rx_queue_full),
        .rx_sync_fall(rx_sync_fall),
        .rx_get_sample(rx_get_sample),
        .rx_bits_cnt_top(rx_bits_cnt_top),
        .rx_error_reg_out(rx_error_reg_out),
        .rx_sync(rx_sync),
        .rx_parity_out(rx_parity_out),

        .rx_sample_cnt_reset(rx_sample_cnt_reset),
        .rx_sample_reg_reset(rx_sample_reg_reset),
        .rx_sample_reg_we(rx_sample_reg_we),
        .rx_parity_reset(rx_parity_reset),
        .rx_parity_we(rx_parity_we),
        .rx_bits_cnt_reset(rx_bits_cnt_reset),
        .rx_bits_cnt_en(rx_bits_cnt_en),
        .parity_error_if_en(parity_error_if_en),
        .rx_queue_we(rx_queue_we),
        .stop_bit_error_if_en(stop_bit_error_if_en),
        .rx_error_reg_set(rx_error_reg_set),
        .rx_error_reg_reset(rx_error_reg_reset)
    );

    /////////////////////////////////////////////////////////////////////////
    // TX CONTROLLER
    /////////////////////////////////////////////////////////////////////////
    module_uart_tx_controller tx_ctrl (
        .clk(clk),
        .reset(reset),
        .parity_en(config_b.parity_type != 2'b0),
        .tx_send_bit(tx_send_bit),
        .tx_queue_empty(tx_queue_empty),
        .double_stop_bit(config_b.double_stop_bits),
        .tx_bits_cnt_top(tx_bits_cnt_top),

        .tx_bits_cnt_reset(tx_bits_cnt_reset),
        .tx_bits_cnt_en(tx_bits_cnt_en),
        .tx_queue_re(tx_queue_re),
        .tx_shift_reg_we(tx_shift_reg_we),
        .tx_shift_reg_se(tx_shift_reg_se),
        .tx_parity_reset(tx_parity_reset),
        .tx_parity_we(tx_parity_we),
        .tx_out_sel(tx_out_sel)
    );

    /////////////////////////////////////////////////////////////////////////
    // RX DATAPATH
    /////////////////////////////////////////////////////////////////////////
    module_uart_rx_datapath #(
        .RX_QUEUE_SIZE(RX_QUEUE_SIZE)
    ) rx_datapath (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_sync_en(1'b1),
        .rx_sample_reg_we(rx_sample_reg_we),
        .rx_sample_reg_reset(rx_sample_reg_reset),
        .rx_queue_we(rx_queue_we),
        .rx_queue_re(re),
        .parity_type(config_b.parity_type[1]),
        .data_bits_count(config_b.data_bits_count),
        .rx_parity_we(rx_parity_we),
        .rx_parity_reset(rx_parity_reset),
        .rx_bits_cnt_en(rx_bits_cnt_en),
        .rx_bits_cnt_reset(rx_bits_cnt_reset),
        .rx_error_reg_set(rx_error_reg_set),
        .rx_error_reg_reset(rx_error_reg_reset),
        .rx_sample_cnt_en(sample_clk_cnt_top),
        .rx_sample_cnt_reset(rx_sample_cnt_reset),

        .rx_sync_rise(),
        .rx_sync_fall(rx_sync_fall),
        .rx_sync(rx_sync),
        .rx_queue_empty(status_a.rx_queue_empty),
        .rx_queue_full(rx_queue_full),
        .rx_queue_dout(rx_queue_dout),
        .rx_parity_out(rx_parity_out),
        .rx_bits_cnt_top(rx_bits_cnt_top),
        .rx_error_reg_out(rx_error_reg_out),
        .rx_sample_cnt_top(),
        .rx_get_sample(rx_get_sample)
    );

    /////////////////////////////////////////////////////////////////////////
    // TX DATAPATH
    /////////////////////////////////////////////////////////////////////////
    module_uart_tx_datapath #(
        .TX_QUEUE_SIZE(TX_QUEUE_SIZE)
    ) tx_datapath (
        .clk(clk),
        .reset(reset),
        .tx_queue_we(tx_queue_we),
        .tx_queue_re(tx_queue_re),
        .tx_queue_din(din[7:0]),
        .tx_shift_reg_we(tx_shift_reg_we),
        .tx_shift_reg_se(tx_shift_reg_se),
        .tx_shift_reg_reset(1'b0),
        .tx_out_sel(tx_out_sel),
        .tx_bits_cnt_en(tx_bits_cnt_en),
        .tx_bits_cnt_reset(tx_bits_cnt_reset),
        .data_bits_count(config_b.data_bits_count),
        .parity_type(config_b.parity_type[1]),
        .tx_parity_we(tx_parity_we),
        .tx_parity_reset(tx_parity_reset),

        .tx(tx),
        .tx_queue_empty(tx_queue_empty),
        .tx_queue_full(status_a.tx_queue_full),
        .tx_bits_cnt_top(tx_bits_cnt_top)
    );

endmodule