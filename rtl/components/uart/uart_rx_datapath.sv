
(* dont_touch = "yes" *) module module_uart_rx_datapath #(
    parameter RX_QUEUE_SIZE = 16
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       rx,
    input  logic       rx_sync_en,
    input  logic       rx_sample_reg_we,
    input  logic       rx_sample_reg_reset,
    input  logic       rx_queue_we,
    input  logic       rx_queue_re,
    input  logic       parity_type,
    input  logic [1:0] data_bits_count,
    input  logic       rx_parity_we,
    input  logic       rx_parity_reset,
    input  logic       rx_bits_cnt_en,
    input  logic       rx_bits_cnt_reset,
    input  logic       rx_error_reg_set,
    input  logic       rx_error_reg_reset,
    input  logic       rx_sample_cnt_en,
    input  logic       rx_sample_cnt_reset,

    output logic       rx_sync_rise,
    output logic       rx_sync_fall,
    output logic       rx_sync,
    output logic       rx_queue_empty,
    output logic       rx_queue_full,
    output logic [7:0] rx_queue_dout,
    output logic       rx_parity_out,
    output logic       rx_bits_cnt_top,
    output logic       rx_error_reg_out,
    output logic       rx_sample_cnt_top,
    output logic       rx_get_sample
);

    /////////////////////////////////////////////////////////////////////////
    // SIGNAL DECLARATIONS
    /////////////////////////////////////////////////////////////////////////
    logic rx_sync_out, rx_get_sample_synchr_in;
    logic [7:0] rx_sample_reg_dout;
    logic [4:0] rx_sample_cnt_val, rx_bits_cnt_max;

    /////////////////////////////////////////////////////////////////////////
    // SIGNAL ASSIGNMENTS
    /////////////////////////////////////////////////////////////////////////
    assign rx_sync                 = rx_sync_out;
    assign rx_get_sample_synchr_in = (rx_sample_cnt_val == 3'h7);
    assign rx_bits_cnt_max         = data_bits_count + 3'h5;
    
    /////////////////////////////////////////////////////////////////////////
    // RX SIGNAL SYNCHRONIZER
    /////////////////////////////////////////////////////////////////////////
    synchronizer #(
        .LEN(1),
        .STAGES(2)
    ) rx_synchr (
        .clk(clk),
        .en(rx_sync_en),
        .dataIn(rx),
        .dataOut(rx_sync_out),
        .rise(rx_sync_rise),
        .fall(rx_sync_fall)
    );

    /////////////////////////////////////////////////////////////////////////
    // RX GET SAMPLE SYNCHRONIZER (used as rising edge detector)
    /////////////////////////////////////////////////////////////////////////
    synchronizer #(
        .LEN(1),
        .STAGES(2)
    ) rx_get_sample_synchr (
        .clk(clk),
        .en(1'b1),
        .dataIn(rx_get_sample_synchr_in),
        .rise(rx_get_sample)
    );

    /////////////////////////////////////////////////////////////////////////
    // RX SAMPLE SHIFT REGISTER
    /////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin : rx_sample_reg_proc
        if (rx_sample_reg_reset) begin
            rx_sample_reg_dout <= 0;
        end else if (rx_sample_reg_we) begin
            rx_sample_reg_dout[6:0] <= rx_sample_reg_dout[7:1];
            rx_sample_reg_dout[7]   <= rx_sync_out;
        end
    end

    /////////////////////////////////////////////////////////////////////////
    // RX QUEUE
    /////////////////////////////////////////////////////////////////////////
    fifo #(
        .XLEN(8),
        .LENGTH(RX_QUEUE_SIZE)
    ) rx_queue (
        .clk(clk),
        .reset(reset),
        .we(rx_queue_we),
        .re(rx_queue_re),
        .din(rx_sample_reg_dout),
        .empty(rx_queue_empty),
        .full(rx_queue_full),
        .dout(rx_queue_dout)
    );

    /////////////////////////////////////////////////////////////////////////
    // RX SERIAL PARITY CALCULATOR
    /////////////////////////////////////////////////////////////////////////
    parity_serial_calculator rx_parity (
        .clk(clk),
        .reset(rx_parity_reset),
        .din(rx_sync_out),
        .we(rx_parity_we),
        .odd(parity_type),
        .parity(rx_parity_out)
    );

    /////////////////////////////////////////////////////////////////////////
    // RX BITS RECIEVED COUNTER
    /////////////////////////////////////////////////////////////////////////
    counter #(
        .COUNTER_WIDTH(4)
    ) rx_bits_cnt (
        .reset(rx_bits_cnt_reset),
        .clk(clk),
        .en(rx_bits_cnt_en),
        .max(rx_bits_cnt_max),
        .top(rx_bits_cnt_top)
    );

    /////////////////////////////////////////////////////////////////////////
    // RX ERROR REGISTER
    /////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin : rx_error_reg_proc
        if (rx_error_reg_reset) begin
            rx_error_reg_out <= 0;
        end else if (rx_error_reg_set) begin
            rx_error_reg_out <= 1;
        end
    end

    /////////////////////////////////////////////////////////////////////////
    // RX SAMPLE COUNTER
    /////////////////////////////////////////////////////////////////////////
    counter #(
        .COUNTER_WIDTH(5)
    ) rx_sample_cnt (
        .reset(rx_sample_cnt_reset),
        .clk(clk),
        .en(rx_sample_cnt_en),
        .max(15),
        .top(rx_sample_cnt_top),
        .val(rx_sample_cnt_val)
    );

endmodule