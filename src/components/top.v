module top(
    input sys_clk
    input sys_res
);

    wire [31:0] instrbus_addr;
    wire [31:0] instrbus_data;

    wire [31:0] databus_addr;
    wire [31:0] databus_datawrite, databus_dataread;
    wire [31:0] databus_mask;
    wire [31:0] databus_writeenable;
    
    ram ram_main(
        .a1(instrbus_addr),
        .do1(instrbus_data),

        .a2(databus_addr),
        .di2(databus_datawrite),
        .do2(databus_dataread),
        .m2(databus_mask),
        .we2(databus_writeenable),
        .clk(sys_clk)
    );

    cpu cpu(
        .clk(sys_clk),
        .reset(sys_res),

        .instruction(instrbus_data),
        .PC(instrbus_addr),

        .memAddr(databus_addr),
        .memReadData(databus_dataread),
        .memWriteData(databus_datawrite),
        .memWr(databus_writeenable),
        .wrMask(databus_writemask),

        .except(),
    );

endmodule