
(* dont_touch = "yes" *) module uart_tx_controller (
    input  logic       clk,
    input  logic       reset,
    input  logic       parity_en,
    input  logic       tx_send_bit,
    input  logic       tx_queue_empty,
    input  logic       double_stop_bit,
    input  logic       tx_bits_cnt_top,

    output logic       tx_bits_cnt_reset,
    output logic       tx_bits_cnt_en,
    output logic       tx_queue_re,
    output logic       tx_shift_reg_we,
    output logic       tx_shift_reg_se,
    output logic       tx_parity_reset,
    output logic       tx_parity_we,
    output logic [1:0] tx_out_sel
);

    /////////////////////////////////////////////////////////////////////////
    // STATES ENUM
    /////////////////////////////////////////////////////////////////////////
    enum {
        TX_IDLE,
        TX_START_BIT,
        TX_HOLD_DATA,
        TX_SEND_DATA,
        TX_PARITY_BIT,
        TX_STOP_BIT_2
    } tx_state, tx_next_state;

    /////////////////////////////////////////////////////////////////////////
    // NEXT STATE REGISTER
    /////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin : tx_state_reg_proc
        if (reset) begin
            tx_state <= TX_IDLE;
        end else begin
            tx_state <= tx_next_state;
        end
    end

    /////////////////////////////////////////////////////////////////////////
    // NEXT STATE LOGIC
    /////////////////////////////////////////////////////////////////////////
    always_comb begin : tx_next_state_logic_proc
        case (tx_state)
            TX_IDLE: begin
                if (tx_send_bit && !tx_queue_empty) begin
                    tx_next_state = TX_START_BIT;
                end else begin
                    tx_next_state = TX_IDLE;
                end
            end

            TX_START_BIT: begin
                if (tx_send_bit) begin
                    tx_next_state = TX_HOLD_DATA;
                end else begin
                    tx_next_state = TX_START_BIT;
                end
            end

            TX_HOLD_DATA: begin
                if (tx_send_bit) begin
                    if (tx_bits_cnt_top) begin
                        if (parity_en) begin
                            tx_next_state = TX_PARITY_BIT;
                        end else begin
                            if (double_stop_bit) begin
                                tx_next_state = TX_STOP_BIT_2;
                            end else begin
                                tx_next_state = TX_IDLE;
                            end
                        end
                    end else begin
                        tx_next_state = TX_SEND_DATA;
                    end
                end else begin
                    tx_next_state = TX_HOLD_DATA;
                end
            end

            TX_SEND_DATA: begin
                tx_next_state = TX_HOLD_DATA;
            end

            TX_PARITY_BIT: begin
                if (tx_send_bit) begin
                    if (double_stop_bit) begin
                        tx_next_state = TX_STOP_BIT_2;
                    end else begin
                        tx_next_state = TX_IDLE;
                    end
                end else begin
                    tx_next_state = TX_PARITY_BIT;
                end
            end

            TX_STOP_BIT_2: begin
                if (tx_send_bit) begin
                    tx_next_state = TX_IDLE;
                end else begin
                    tx_next_state = TX_STOP_BIT_2;
                end
            end

            default: tx_next_state = TX_IDLE;
        endcase
    end

    /////////////////////////////////////////////////////////////////////////
    // OUTPUT LOGIC
    /////////////////////////////////////////////////////////////////////////
    always_comb begin : tx_output_logic_proc
        tx_bits_cnt_reset = 0;
        tx_bits_cnt_en    = 0;
        tx_queue_re       = 0;
        tx_shift_reg_we   = 0;
        tx_shift_reg_se   = 0;
        tx_parity_reset   = 0;
        tx_parity_we      = 0;
        tx_out_sel        = 0;

        case (tx_state)
            TX_IDLE: begin
                if (tx_send_bit && !tx_queue_empty) begin
                    tx_queue_re       = 1;
                    tx_shift_reg_we   = 1;
                    tx_bits_cnt_reset = 1;
                    tx_parity_reset   = 1;
                end else begin
                    tx_out_sel = 2'b01;
                end
            end

            TX_START_BIT: begin
                if (tx_send_bit) begin
                    tx_bits_cnt_en  = 1;
                    tx_out_sel      = 2'b10;
                    tx_parity_we    = 1;
                end
            end

            TX_HOLD_DATA: begin
                if (tx_send_bit) begin
                    if (tx_bits_cnt_top) begin
                        if (parity_en) begin
                            tx_out_sel = 2'b11;
                        end else begin
                            tx_out_sel = 2'b01;
                        end
                    end else begin
                        tx_bits_cnt_en  = 1;
                        tx_out_sel      = 2'b10;
                        tx_shift_reg_se = 1;
                    end
                end else begin
                    tx_out_sel = 2'b10;
                end
            end

            TX_SEND_DATA: begin
                tx_out_sel   = 2'b10;
                tx_parity_we = 1;
            end

            TX_PARITY_BIT: begin
                if (tx_send_bit) begin
                    tx_out_sel = 2'b01;
                end else begin
                    tx_out_sel = 2'b11;
                end
            end

            TX_STOP_BIT_2: begin
                tx_out_sel = 2'b01;
            end

            default: begin end
        endcase
    end

endmodule