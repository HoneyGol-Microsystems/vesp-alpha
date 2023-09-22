`ifndef __FILE_GPIO_V
`define __FILE_GPIO_V

module gpio (
    input  [1:0]  regSel, // select register
    input         we,
    input         reset,
    input         clk,
    input  [31:0] di, // data to write to selected register
    output [31:0] do, // data to read from selected register
    inout         ports // TODO: specify bit width
);

    reg [31:0] GPIODATA [3:0];
    reg [31:0] GPIODIR [3:0];
    reg [31:0] GPIOMODE [3:0];

    assign do = GPIODATA[regSel];

    always @(posedge clk) begin
        if (we) begin
            if (reset) begin
                GPIODATA[regSel] <= 0;
            end else begin
                GPIODATA[regSel] <= di;
            end
        end
    end
    
endmodule

`endif // __FILE_GPIO_V