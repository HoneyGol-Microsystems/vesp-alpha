
module uart_top (
    input logic        clk,
    input logic        reset,
    input logic        rx,
    input logic        re,
    input logic        we,
    input logic [2:0]  regsel,
    input logic [31:0] din,

    output logic        tx,
    output logic        par_irq,
    output logic        stop_bit_irq,
    output logic [31:0] dout
);

    /////////////////////////////////////////////////////////////////////////
    // SIGNAL DECLARATIONS
    /////////////////////////////////////////////////////////////////////////
    logic stop_bit_error_if_out, stop_bit_error_if_en, parity_error_if_out,
          parity_error_if_en, tx_queue_empty_if_out, tx_queue_empty,
          rx_sync_out, rx_parity_out;

    /////////////////////////////////////////////////////////////////////////
    // SIGNAL ASSIGNMENTS
    /////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////
    // CONFIG/STATUS REGISTERS
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

    /////////////////////////////////////////////////////////////////////////
    // INTERRUPT FLAG REGISTERS
    /////////////////////////////////////////////////////////////////////////
    // TX queue empty IF register
    always_ff @(posedge clk) begin : tx_queue_empty_if_proc
        if (config_a.tx_queue_empty_irq_en) begin
            tx_queue_empty_if_out <= tx_queue_empty;
        end
    end

    // RX queue full IF register

    // parity error IF register
    always_ff @(posedge clk) begin : parity_error_if_proc
        if (config_b.parity_error_irq_en && parity_error_if_en) begin
            parity_error_if_out <= rx_parity_out;
        end
    end

    // stop bit error IF register
    always_ff @(posedge clk) begin : stop_bit_error_if_proc
        if (config_b.stop_bit_error_irq_en && stop_bit_error_if_en) begin
            stop_bit_error_if_out <= !rx_sync_out;
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
            default: dout = { {16{1'b0}}, status_a     , { 8{1'b0}} };
        endcase
    end

endmodule