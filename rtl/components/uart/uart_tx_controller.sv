
module uart_tx_controller (
    input  logic       clk,
    input  logic       tx_clk_en,
    input  logic       reset,
    input  logic       parity_en,
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
            if (tx_clk_en) begin
                tx_state <= tx_next_state;
            end
        end
    end

    /////////////////////////////////////////////////////////////////////////
    // NEXT STATE LOGIC
    /////////////////////////////////////////////////////////////////////////
    always_comb begin : tx_next_state_logic_proc
        case (tx_state)
            TX_IDLE: begin
                if (!tx_queue_empty) begin
                   tx_next_state = TX_SEND_DATA;
                end else begin
                   tx_next_state = TX_IDLE;
                end
            end

            TX_SEND_DATA: begin
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
            end

            TX_PARITY_BIT: begin
                if (double_stop_bit) begin
                    tx_next_state = TX_STOP_BIT_2;
                end else begin
                    tx_next_state = TX_IDLE;
                end
            end

            TX_STOP_BIT_2: begin
                tx_logic_next_state = TX_IDLE;
            end
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
                if (tx_queue_empty) begin
                    tx_out_sel = 2'b01;
                end else begin
                    tx_queue_re       = 1;
                    tx_shift_reg_we   = 1;
                    tx_bits_cnt_reset = 1;
                    tx_parity_reset   = 1;
                end
            end

            TX_SEND_DATA: begin
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
                    tx_parity_we    = 1;
                end
            end

            TX_PARITY_BIT: begin
                tx_out_sel = 2'b01;
            end

            TX_STOP_BIT_2: begin
                tx_out_sel = 2'b01;
            end
        endcase
    end

endmodule