`ifndef __FILE_GPIO_V
`define __FILE_GPIO_V

(* dont_touch = "yes" *) module gpio (
    input      [2:0]  regSel,   // select register
    input             we,
    input             reset,
    input             clk,
    input      [31:0] di,       // data to write to selected register
    output reg [31:0] do,       // data to read from selected register
    inout      [15:0] ports     // to/from external ports
);

    reg [7:0] GPIOWR_A, GPIODIR_A, GPIOWR_B, GPIODIR_B;

    always @(*) begin
        case (regSel)
            3'b000:  do = { {24{1'b0}}, GPIOWR_A                };
            3'b001:  do = { {16{1'b0}}, GPIODIR_A,   {8{1'b0}}  };
            3'b010:  do = { {8{1'b0}} , ports[7:0] , {16{1'b0}} };
            3'b011:  do = { GPIOWR_B  , {8{1'b0}}               };
            3'b100:  do = { {24{1'b0}}, GPIODIR_B               };
            default: do = { {16{1'b0}}, ports[15:8], {8{1'b0}}  };
        endcase    
    end

    always @(posedge clk) begin
        if (reset) begin
            GPIOWR_A  <= 8'h00;
            GPIODIR_A <= 8'h00;
            GPIOWR_B  <= 8'h00;
            GPIODIR_B <= 8'h00;
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

    // writing to ports
    genvar i;
    for (i = 0; i < 8; i = i + 1) begin
        // 1 -> output, 0 -> input
        assign ports[i]     = GPIODIR_A[i] ? GPIOWR_A[i] : 1'bZ;
        assign ports[i + 8] = GPIODIR_B[i] ? GPIOWR_B[i] : 1'bZ;
    end

endmodule

`endif // __FILE_GPIO_V