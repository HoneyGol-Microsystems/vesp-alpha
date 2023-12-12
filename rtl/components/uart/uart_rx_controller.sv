
module uart_rx_controller (
    input  logic clk,
    input  logic rx_clk_en,
    input  logic reset,
    input  logic parity_en,
    input  logic double_stop_bit,
    input  logic rx_queue_full,
    input  logic rx_sync_fall,
    input  logic rx_get_sample,
    input  logic rx_bits_cnt_top,
    input  logic rx_error_reg_out,
    input  logic rx_sync_out,

    output logic rx_sample_cnt_reset,
    output logic rx_sample_reg_reset,
    output logic rx_sample_reg_we,
    output logic rx_parity_reset,
    output logic rx_parity_we,
    output logic rx_bits_cnt_reset,
    output logic rx_bits_cnt_en,
    output logic parity_error_if_en,
    output logic rx_queue_we,
    output logic stop_bit_error_if_en,
    output logic rx_error_reg_set,
    output logic rx_error_reg_reset
);

    /////////////////////////////////////////////////////////////////////////
    // STATES ENUM
    /////////////////////////////////////////////////////////////////////////
    enum {
        RX_IDLE,
        RX_WAIT_START,
        RX_WAIT_DATA,
        RX_READ_DATA,
        RX_DATA_DONE,
        RX_PARITY_BIT,
        RX_WAIT_STOP_BIT_1,
        RX_WAIT_STOP_BIT_2
    } rx_state, rx_next_state;

    /////////////////////////////////////////////////////////////////////////
    // NEXT STATE REGISTER
    /////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin : rx_state_reg_proc
        if (reset) begin
            rx_state <= RX_IDLE;
        end else begin
            if (rx_clk_en) begin
                rx_state <= rx_next_state;
            end
        end
    end

    /////////////////////////////////////////////////////////////////////////
    // NEXT STATE LOGIC
    /////////////////////////////////////////////////////////////////////////
    always_comb begin : rx_next_state_logic_proc
        case (rx_state)
            RX_IDLE: begin
                if (!rx_queue_full && rx_sync_fall) begin
                    rx_next_state = RX_WAIT_START;
                end else begin
                    rx_next_state = RX_IDLE;
                end
            end

            RX_WAIT_START: begin
                if (rx_get_sample) begin
                    rx_next_state = RX_WAIT_DATA;
                end else begin
                    rx_next_state = RX_WAIT_START;
                end
            end

            RX_WAIT_DATA: begin
                if (rx_bits_cnt_top) begin
                    rx_next_state = RX_DATA_DONE;
                end else begin
                    if (rx_get_sample) begin
                        rx_next_state = RX_READ_DATA;
                    end else begin
                        rx_next_state = RX_WAIT_DATA;
                    end
                end
            end

            RX_READ_DATA: begin
                rx_next_state = RX_WAIT_DATA;
            end

            RX_DATA_DONE: begin
                if (parity_en) begin
                    if (rx_get_sample) begin
                        rx_next_state = RX_PARITY_BIT;
                    end else begin
                        rx_next_state = RX_DATA_DONE;
                    end
                end else begin
                    rx_next_state = RX_WAIT_STOP_BIT_1;
                end
            end

            RX_PARITY_BIT: begin
                rx_next_state = RX_WAIT_STOP_BIT_1;
            end

            RX_WAIT_STOP_BIT_1: begin
                if (rx_get_sample) begin
                    if (double_stop_bit) begin
                        rx_next_state = RX_WAIT_STOP_BIT_2;
                    end else begin
                        rx_next_state = RX_IDLE;
                    end
                end else begin
                    rx_next_state = RX_WAIT_STOP_BIT_1;
                end
            end

            RX_WAIT_STOP_BIT_2: begin
                if (rx_get_sample) begin
                    rx_next_state = RX_IDLE;
                end else begin
                    rx_next_state = RX_WAIT_STOP_BIT_2;
                end
            end
        endcase
    end

    /////////////////////////////////////////////////////////////////////////
    // OUTPUT LOGIC
    /////////////////////////////////////////////////////////////////////////
    always_comb begin : rx_output_logic_proc
        rx_sample_cnt_reset  = 0;
        rx_sample_reg_reset  = 0;
        rx_sample_reg_we     = 0;
        rx_parity_reset      = 0;
        rx_parity_we         = 0;
        rx_bits_cnt_reset    = 0;
        rx_bits_cnt_en       = 0;
        parity_error_if_en   = 0;
        rx_queue_we          = 0;
        stop_bit_error_if_en = 0;
        rx_error_reg_set     = 0;
        rx_error_reg_reset   = 0;

        case (rx_state)
            RX_IDLE: begin
                if (!rx_queue_full && rx_sync_fall) begin
                    rx_sample_cnt_reset = 1;
                end
            end

            RX_WAIT_START: begin
                if (rx_get_sample) begin
                    rx_sample_reg_reset = 1;
                    rx_parity_reset     = 1;
                    rx_bits_cnt_reset   = 1;
                end
            end

            RX_WAIT_DATA: begin
                if (!rx_bits_cnt_top && rx_get_sample) begin
                    rx_sample_reg_we = 1;
                    rx_parity_we     = 1;
                end
            end

            RX_READ_DATA: begin
                rx_bits_cnt_en = 1;
            end

            RX_DATA_DONE: begin
                if (parity_en && rx_get_sample) begin
                    rx_parity_we = 1;
                end
            end

            RX_PARITY_BIT: begin
                parity_error_if_en = 1;
            end

            RX_WAIT_STOP_BIT_1: begin
                if (rx_get_sample) begin
                    if (double_stop_bit) begin
                        rx_error_reg_set     = !rx_sync_out;
                        stop_bit_error_if_en = 1;
                    end else begin
                        rx_queue_we          = !rx_error_reg_out && rx_sync_out;
                        stop_bit_error_if_en = 1;
                        rx_error_reg_reset   = 1;
                    end
                end
            end

            RX_WAIT_STOP_BIT_2: begin
                if (rx_get_sample) begin
                    rx_queue_we          = !rx_error_reg_out && rx_sync_out;
                    stop_bit_error_if_en = 1;
                    rx_error_reg_reset   = 1;
                end
            end
        endcase
    end

endmodule