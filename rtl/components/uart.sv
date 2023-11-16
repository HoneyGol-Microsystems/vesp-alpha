module uart #(
    parameter DATA_WIDTH    = 32,
    parameter RX_QUEUE_SIZE = 16,
    parameter TX_QUEUE_SIZE = 16
) (
    input  logic                   we;
    input  logic [2:0]             regsel;
    input  logic [DATA_WIDTH-1:0]  din;
    input  logic                   clk;
    input  logic                   reset;

    output logic                   irq; 
    output logic [DATA_WIDTH-1:0]  dout;
    output logic                   tx;
    output logic                   rx;
);

    logic [4:0] main_clk_timer_val;
    logic       main_clk;
    logic [3:0] bit_clk_timer_val;
    logic       bit_clk;

    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic [7:0] config_a;
    logic [7:0] status_a;

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

    //////////////////////////////////////////////////
    // QUEUES
    //////////////////////////////////////////////////

    assign rx_re = !we && ( regsel == 3'h1 );
    assign status_a = { tx_full, rx_empty, 6'b0 };

    assign tx_we = we && ( regsel == 3'h0 );

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
        .do(rx_data)
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
        .do(tx_do)
    );

    //////////////////////////////////////////////////
    // REGISTER INTERFACE
    //////////////////////////////////////////////////

    always_ff @( posedge clk ) begin : register_write
        if ( we ) begin
            case ( regsel )
                // TX data.
                3'h0: begin
                    tx_data <= din[7:0];
                end
                // Config register A.
                3'h2: begin
                    config_a <= din[23:16]
                end
                default: begin end
            endcase
        end
    end

    always_comb begin : register_read
        case ( regsel )
            3'h0:    dout = { 24{ 1'b0 }, tx_data               };
            3'h1:    dout = { 16{ 1'b0 }, rx_data,   8{ 1'b0  } };
            3'h2:    dout = {  8{ 1'b0 }, config_a, 16{ 1'b0 }  };
            default: dout = { 16{ 1'b0 }, status_a,  8{ 1'b0  } };
        endcase
    end

    //////////////////////////////////////////////////
    // CLOCK DIVIDERS
    //////////////////////////////////////////////////

    always_ff @( posedge clk ) begin : main_clk_timer
        if ( reset )
            main_clk_timer <= 0;
        else
            main_clk_timer <= main_clk_timer + 1;
    end

    assign main_clk = main_clk_timer == 26;

    always_ff @( posedge clk ) begin : bit_clk_timer
        if ( reset )
            bit_clk_timer_val <= 0;
        else
            bit_clk_timer_val <= bit_clk_timer_val + 1;
    end

    assign bit_clk = bit_clk_timer == 15;

    //////////////////////////////////////////////////
    // RX/TX
    //////////////////////////////////////////////////

    

endmodule