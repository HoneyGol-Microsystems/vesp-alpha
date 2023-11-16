module moduleName #(
    parameter DATA_WIDTH    = 32,
    parameter RX_QUEUE_SIZE = 16,
    parameter TX_QUEUE_SIZE = 16
) (
    input  logic                   we;
    input  logic [2:0]             regsel;
    input  logic [DATA_WIDTH-1:0]  din;
    input  logic                   clk;

    output logic                   irq; 
    output logic [DATA_WIDTH-1:0]  dout;
    output logic                   tx;
    output logic                   rx;
);

    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic [7:0] config_a;
    logic [7:0] status_a;

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
    
endmodule