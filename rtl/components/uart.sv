module uart #(
    parameter DATA_WIDTH    = 32,
    parameter RX_QUEUE_SIZE = 16,
    parameter TX_QUEUE_SIZE = 16
) (
    input  logic                  we,
    input  logic                  sel,
    input  logic [2:0]            regsel,
    input  logic [DATA_WIDTH-1:0] din,
    input  logic                  clk,
    input  logic                  reset,

    output logic                  irq,
    output logic [DATA_WIDTH-1:0] dout,
    output logic                  tx,
    input  logic                  rx
);

    logic [4:0] ref_clk_timer_val;
    logic       ref_clk;

    logic [4:0] main_clk_timer_val;
    logic       main_clk;
    logic [3:0] bit_clk_timer_val;
    logic       bit_clk;

    logic [7:0] tx_data;
    logic [7:0] rx_data;

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

    logic [3:0] total_data_bits_count;

    logic rx_we;
    logic rx_re;
    logic rx_di;
    logic rx_empty;
    logic rx_full;

    logic tx_we;
    logic tx_re;
    logic tx_do;
    logic tx_empty;
    logic tx_full;

    enum {
        TX_IDLE,
        TX_START_BIT,
        TX_DATA_BIT,
        TX_PAR_BIT,
        TX_END_BIT_1,
        TX_END_BIT_2
    } tx_logic_state, tx_logic_next_state;

    logic [7:0] tx_out_buffer;
    logic [3:0] tx_bits_sent_count;

    assign total_data_bits_count = config_b.data_bits_count + 5;

    //////////////////////////////////////////////////
    // QUEUES
    //////////////////////////////////////////////////

    // nelze !!! provedlo by se u kazdeho shodneho regselu
    assign rx_re = sel && !we && ( regsel == 3'h1 );
    
    assign status_a.tx_queue_full = tx_full;
    assign status_a.rx_queue_empty = rx_empty;
    assign status_a.reserved = 0;

    assign tx_we = sel && we && ( regsel == 3'h0 );

    fifo #(
        .XLEN(8),
        .LENGTH(RX_QUEUE_SIZE)
    ) rx_queue (
        .clk(clk),
        .reset(reset),
        .we(rx_we),
        .re(rx_re),
        .di(rx_di),
        .empty(rx_empty),
        .full(rx_full),
        .dout(rx_data)
    );

    fifo #(
        .XLEN(8),
        .LENGTH(TX_QUEUE_SIZE)
    ) tx_queue (
        .clk(clk),
        .reset(reset),
        .we(tx_we),
        .re(tx_re),
        .di(tx_data),
        .empty(tx_empty),
        .full(tx_full),
        .dout(tx_do)
    );

    //////////////////////////////////////////////////
    // REGISTER INTERFACE
    //////////////////////////////////////////////////

    always_ff @( posedge clk ) begin : proc_register_write
        if ( we ) begin
            case ( regsel )
                // TX data.
                3'h0: begin
                    tx_data <= din[7:0];
                end
                // Config register A.
                3'h2: begin
                    config_a <= din[23:16];
                end
                // Config register B.
                3'h3: begin
                    config_b <= din[31:24];
                end
                default: begin end
            endcase
        end
    end

    always_comb begin : proc_register_read
        case ( regsel )
            3'h0:    dout = { { 24{ 1'b0 } }, tx_data                  };
            3'h1:    dout = { { 16{ 1'b0 } }, rx_data,  {  8{ 1'b0 } } };
            3'h2:    dout = { {  8{ 1'b0 } }, config_a, { 16{ 1'b0 } } };
            3'h3:    dout = {                 config_b, { 24{ 1'b0 } } };
            default: dout = { { 16{ 1'b0 } }, status_a, {  8{ 1'b0 } } };
        endcase
    end

    //////////////////////////////////////////////////
    // CLOCK DIVIDERS
    //////////////////////////////////////////////////
    // Reference clock. Generates 3.7037 MHz from 100 MHz system clock.
    always_ff @( posedge clk ) begin : proc_ref_clk_timer
        if ( reset )
            ref_clk_timer_val <= 0;
        else
            ref_clk_timer_val <= ref_clk_timer_val + 1;
    end
    assign ref_clk = (ref_clk_timer_val == 26);

    // Main clock - used for RX sampling. Configurable.
    always_ff @( posedge clk ) begin : proc_main_clk_timer
        if ( reset )
            main_clk_timer_val <= 0;
        else if ( ref_clk )
            main_clk_timer_val <= main_clk_timer_val + 1;
    end
    assign main_clk = (main_clk_timer_val == config_a.clock_divisor);

    always_ff @( posedge clk ) begin : proc_bit_clk_timer
        if ( reset )
            bit_clk_timer_val <= 0;
        else if ( main_clk )
            bit_clk_timer_val <= bit_clk_timer_val + 1;
    end
    assign bit_clk = (bit_clk_timer_val == 15);

    //////////////////////////////////////////////////
    // TX logic controller
    //////////////////////////////////////////////////
    always_ff @( posedge clk ) begin : proc_tx_logic_ff
        if ( reset ) begin
            tx_logic_state <= TX_IDLE;
        end else begin
            tx_logic_state <= tx_logic_next_state;
        end
    end

    always_comb begin : proc_tx_logic_lookup

        case ( tx_logic_state )
            TX_IDLE: begin
                if ( !tx_empty ) begin
                   tx_logic_next_state = TX_START_BIT;
                end else begin
                   tx_logic_next_state = TX_IDLE;
                end
            end

            TX_START_BIT: begin
                tx_logic_next_state = TX_DATA_BIT;
            end

            TX_DATA_BIT: begin
                
            end

            TX_PAR_BIT: begin
                tx_logic_next_state = TX_END_BIT_1;
            end

            TX_END_BIT_1: begin
                if ( config_b.double_stop_bits ) begin
                    tx_logic_next_state = TX_END_BIT_2;
                end else begin
                    tx_logic_next_state = TX_IDLE;
                end
            end

            TX_END_BIT_2: begin
                tx_logic_next_state = TX_IDLE;
            end
        endcase
    end

    always_comb begin : proc_tx_logic_output

    end
    

endmodule