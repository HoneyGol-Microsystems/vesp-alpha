`ifndef __FILE_GPIO_V
`define __FILE_GPIO_V

(* dont_touch = "yes" *) module gpio (
    input  logic [2:0]  regSel,   // select register
    input  logic        we,
    input  logic        clk,
    input  logic [31:0] di,       // data to write to selected register
    output logic [31:0] dout,       // data to read from selected register
    inout  logic [15:0] ports     // to/from external ports
);

    logic [7:0] GPIOWR_A, GPIODIR_A, GPIOWR_B, GPIODIR_B;

    always_comb @(*) begin
        case (regSel)
            3'b000:  dout = { {24{1'b0}}, GPIOWR_A                };
            3'b001:  dout = { {16{1'b0}}, GPIODIR_A,   {8{1'b0}}  };
            3'b010:  dout = { {8{1'b0}} , ports[7:0] , {16{1'b0}} };
            3'b011:  dout = { GPIOWR_B  , {24{1'b0}}              };
            3'b100:  dout = { {24{1'b0}}, GPIODIR_B               };
            default: dout = { {16{1'b0}}, ports[15:8], {8{1'b0}}  };
        endcase    
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            GPIOWR_A  <= 0;
            GPIODIR_A <= 0;
            GPIOWR_B  <= 0;
            GPIODIR_B <= 0;
        end else if (we) begin
            case (regSel)
                3'b000:  GPIOWR_A  <= di[7:0];
                3'b001:  GPIODIR_A <= di[15:8];
                // 010:  ignore writes to GPIORD
                3'b011:  GPIOWR_B  <= di[31:24];
                3'b100:  GPIODIR_B <= di[7:0];
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
            // 0 -> output, 1 -> input
            assign ports[i]     = GPIODIR_A[i] ? 1'bZ : GPIOWR_A[i];
            assign ports[i + 8] = GPIODIR_B[i] ? 1'bZ : GPIOWR_B[i];
        end
    endgenerate

endmodule

`endif // __FILE_GPIO_V