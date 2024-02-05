`ifndef __FILE_GPIO_V
`define __FILE_GPIO_V

(* dont_touch = "yes" *) module module_gpio (
    input  logic [2:0]  reg_sel,   // select register
    input  logic        we,
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] din,       // data to write to selected register

    output logic [31:0] dout,       // data to read from selected register

    inout  logic [15:0] ports     // to/from external ports
);

    logic [7:0] GPIOWR_A;
    logic [7:0] GPIODIR_A;
    logic [7:0] GPIORD_A;
    logic [7:0] GPIOWR_B;
    logic [7:0] GPIODIR_B;
    logic [7:0] GPIORD_B;

    always_comb begin : register_read_proc
        case (reg_sel)
            3'b000:  dout = { {24{1'b0}}, GPIOWR_A                };
            3'b001:  dout = { {16{1'b0}}, GPIODIR_A,   {8{1'b0}}  };
            3'b010:  dout = { {8{1'b0}} , GPIORD_A , {16{1'b0}} };
            3'b011:  dout = { GPIOWR_B  , {24{1'b0}}              };
            3'b100:  dout = { {24{1'b0}}, GPIODIR_B               };
            default: dout = { {16{1'b0}}, GPIORD_B, {8{1'b0}}  };
        endcase    
    end

    always_ff @(posedge clk) begin : input_ff_proc
        GPIORD_A <= ports[7:0];
        GPIORD_B <= ports[15:8];
    end

    always_ff @(posedge clk) begin : register_write_proc
        if (reset) begin
            // Default direction of GPIOs should be "input".
            // Reason: If there is a bad intitial write value,
            // it could cause a short.
            GPIOWR_A  <= 0;
            GPIODIR_A <= 0;
            GPIOWR_B  <= 0;
            GPIODIR_B <= 0;
        end else if (we) begin
            case (reg_sel)
                3'b000:  GPIOWR_A  <= din[7:0];
                3'b001:  GPIODIR_A <= din[15:8];
                // 010:  ignore writes to GPIORD
                3'b011:  GPIOWR_B  <= din[31:24];
                3'b100:  GPIODIR_B <= din[7:0];
                // 101:  ignore writes to GPIORD
                default: begin end
            endcase    
        end
    end

    // This description can be used to infer IOBUF correctly
    // in Xilinx's tools (and I hope in many others as well).
    // It is better than using proprietary block explicitly (in terms of portability).
    generate
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin
            // 1 -> output, 0 -> input
            assign ports[i]     = GPIODIR_A[i] ? GPIOWR_A[i] : 1'bZ;
            assign ports[i + 8] = GPIODIR_B[i] ? GPIOWR_B[i] : 1'bZ;
        end
    endgenerate

endmodule

`endif // __FILE_GPIO_V