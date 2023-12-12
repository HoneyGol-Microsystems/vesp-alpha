
module uart_top (
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
          rx_queue_full, rx_sync, rx_parity_out, if_reg_reset;
    logic [7:0] tx_queue_din, tx_queue_dout, rx_queue_dout;

    /////////////////////////////////////////////////////////////////////////
    // SIGNAL ASSIGNMENTS
    /////////////////////////////////////////////////////////////////////////
    assign if_reg_reset = (we && regsel == 3'h6);

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
        end else if (config_b.parity_error_irq_en && parity_error_if_en) begin
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
            3'h5:    dout = { {16{1'b0}}, status_a     , { 8{1'b0}} };
            default: dout = { { 8{1'b0}}, if_reg       , {16{1'b0}} };
        endcase
    end

endmodule