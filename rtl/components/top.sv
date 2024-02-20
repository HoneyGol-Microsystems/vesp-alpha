`ifndef __FILE_TOP_V
`define __FILE_TOP_V

(* dont_touch = "yes" *) module module_top # (
    parameter MEM_ARCH = "harvard"
) (
    input clk,
    input reset,

    inout [15:0] gpio_ports
);

    logic d_we, data_mem_we, gpio_we;
    logic [2:0] d_read_sel;
    logic [3:0] d_mask;
    logic [31:0] i_addr, i_read, d_addr, d_write, data_mem_dout, gpio_dout,
                 d_read, millis_timer_dout;

    module_address_decoder address_decoder (
        .we(d_we),
        .a(d_addr),

        .outsel(d_read_sel),
        .wemem(data_mem_we),
        .wegpio(gpio_we)
    );

    module_gpio gpio (
        .reg_sel(d_addr[2:0]),
        .we(gpio_we),
        .reset(reset),
        .clk(clk),
        .din(d_write),

        .dout(gpio_dout),

        .ports(gpio_ports)
    );

    module_millis_timer #(
        .TIMER_WIDTH(32),
        .CLK_FREQ_HZ(50000000)
    ) millis_timer (
        .clk(clk),
        .reset(reset),

        .dout(millis_timer_dout)
    );

    generate
        if (MEM_ARCH == "harvard") begin : gen_memory
            module_instruction_memory #(
                .WORD_CNT(`INSTR_MEM_WORD_CNT),
                .MEM_FILE("software/firmware_text.mem")
            ) instruction_memory (
                .a(i_addr),

                .d(i_read)
            );

            module_data_memory #(
                .WORD_CNT(`DATA_MEM_WORD_CNT),
                .MEM_FILE("software/firmware_data.mem")
            ) data_memory (
                .clk(clk),
                .we(d_we),
                .mask(d_mask),
                .a(d_addr),
                .din(d_write),

                .dout(data_mem_dout)
            );
        end else if (MEM_ARCH == "neumann") begin : gen_memory
            module_ram #(
                .WORD_CNT(`RAM_WORD_CNT),
                .MEM_FILE("")
            ) ram (
                .clk(clk),
                .a1(i_addr),
                .a2(d_addr),
                .di2(d_write),
                .m2(d_mask),
                .we2(d_we),

                .do1(i_read),
                .do2(data_mem_dout)
            );
        end else begin
            $fatal("Unknown memory architecture specified.");
        end
    endgenerate

    module_cpu cpu (
        .clk(clk),
        .reset(reset),
        .instruction(i_read),
        .pc(i_addr),

        .mem_addr(d_addr),
        .mem_rd_data(d_read),
        .mem_wr_data(d_write),
        .mem_we(d_we),
        .mem_mask(d_mask)
    );

    // CPU data read source select.
    always_comb begin
        case (d_read_sel)
            3'b000:  d_read = data_mem_dout;
            3'b001:  d_read = gpio_dout;
            3'b011:  d_read = millis_timer_dout;
            default: d_read = 0;
        endcase
    end

endmodule

`endif // __FILE_TOP_V