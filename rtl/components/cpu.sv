`ifndef __FILE_CPU_V
`define __FILE_CPU_V

(* dont_touch = "yes" *) module module_cpu (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instruction,
    input  logic [31:0] mem_rd_data,

    output logic        mem_we,  // write enable to data memory
    output logic [3:0]  mem_mask,
    output logic [31:0] pc,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wr_data
);

    // wire/reg declarations
    logic alu_zero, alu_to_pc, mem_to_reg, reg_we, rs2_shift_sel, uext, csr_we,
          branch, mret, interrupt, irq_bus, exception, int_exc;
    logic [1:0] load_sel, mask_sel, alu_src1, alu_src2;
    logic [2:0] reg_data_sel;
    logic [3:0] alu_ctrl, mask;
    logic [4:0] rs2_shift;
    logic [7:0] data_lb;
    logic [15:0] data_lh;
    logic [30:0] int_code, exc_code;
    logic [31:0] src1, rs1, rs2, alu_res, imm, imm_pc, branch_target, reg_res,
                 data_ext_lb, data_ext_lh, pc4, csr_out, mepc_out, mtvec_out,
                 mcause_out, mcause_in, next_pc, next_pc_int, branch_mret_target,
                 int_exc_code, next_mepc, isr_address, reg_data, mem_data, src2;

    // module instantiations
    module_controller controller (
        .instruction(instruction),
        .mem_addr(mem_addr),
        .alu_zero(alu_zero),
        .interrupt(interrupt),
        .clk(clk),
        .reset(reset),

        .alu_ctrl(alu_ctrl),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .alu_to_pc(alu_to_pc),
        .branch(branch),
        .load_sel(load_sel),
        .mask_sel(mask_sel),
        .mem_to_reg(mem_to_reg),
        .mem_we(mem_we),
        .reg_data_sel(reg_data_sel),
        .reg_we(reg_we),
        .rs2_shift_sel(rs2_shift_sel),
        .uext(uext),
        .csr_we(csr_we),
        .mret(mret),
        .exception(exception),
        .exc_code(exc_code)
    );

    module_alu #(
        .XLEN(`XLEN)
    ) alu (
        .op1(src1),
        .op2(src2),
        .ctrl(alu_ctrl),

        .zero(alu_zero),
        .res(alu_res)
    );

    module_imm_decoder imm_decoder (
        .instruction(instruction),

        .imm(imm)
    );

    module_register_file32 #(
        .XLEN(`XLEN)
    ) register_file32 (
        .clk(clk),
        .we3(reg_we),
        .a1(instruction[19:15]),
        .a2(instruction[24:20]),
        .a3(instruction[11:7]),
        .di3(reg_res),

        .rd1(rs1),
        .rd2(rs2)
    );

    module_interrupt_controller #(
        .EXT_IRQ_COUNT(1)
    ) interrupt_controller (
        .clk(clk),
        .irq_bus(irq_bus),

        .interrupt(interrupt),
        .int_code(int_code)
    );

    module_csr csr (
        .clk(clk),
        .reset(reset),
        .we(csr_we),
        .mepc_we(int_exc),
        .mcause_we(int_exc),
        .a(instruction[31:20]),
        .din(alu_res),
        .mepc_din(next_mepc),
        .mcause_din(int_exc_code),

        .dout(csr_out),
        .mepc_dout(mepc_out),
        .mtvec_dout(mtvec_out),
        .mcause_dout(mcause_out)
    );

    module_extend #(
        .DATA_LEN(8),
        .RES_LEN(`XLEN)
    ) ext8to32 (
        .data(data_lb),
        .uext(uext),

        .res(data_ext_lb)
    );

    module_extend #(
        .DATA_LEN(16),
        .RES_LEN(`XLEN)
    ) ext16to32 (
        .data(data_lh),
        .uext(uext),

        .res(data_ext_lh)
    );

    // assignments (including 1bit muxes)
    assign pc4                = pc + 4;
    assign imm_pc             = imm + pc;
    assign branch_target      = alu_to_pc ? alu_res : imm_pc;
    assign src1               = alu_src1 ? imm : rs1;
    assign rs2_shift          = rs2_shift_sel ? {alu_res[1], 4'b0} : {alu_res[1:0], 3'b0};
    assign mem_wr_data        = rs2 << rs2_shift;
    assign mem_addr           = alu_res;
    assign mem_mask           = mask << alu_res[1:0];
    assign data_lh            = alu_res[1] ? mem_rd_data[31:16] : mem_rd_data[15:0];
    assign reg_res            = mem_to_reg ? mem_data : reg_data;
    assign branch_mret_target = mret ? mepc_out : branch_target;
    assign next_pc            = branch || mret ? branch_mret_target : pc4;
    assign next_pc_int        = int_exc ? isr_address : next_pc;

    assign int_exc_code       = {interrupt, interrupt ? int_code : exc_code};
    assign int_exc            = interrupt | exception;
    assign next_mepc          = exception ? pc : next_pc;

    // ISR decoder block
    assign isr_address        = (mcause_out[31] && mtvec_out[0]) ? 
                                    {mtvec_out[31:2], 2'b00} + (mcause_out << 2)
                                    :
                                    {mtvec_out[31:2], 2'b00};

    // PCREG
    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= 0;
        end else begin
            pc <= next_pc_int;
        end
    end

    // alu_src2 mux
    always_comb begin
        case (alu_src2)
            2'b00:   src2 = rs2;
            2'b01:   src2 = imm;
            default: src2 = csr_out;
        endcase
    end

    // mask_sel mux
    always_comb begin
        case (mask_sel)
            2'b00:   mask = 4'b0001;
            2'b01:   mask = 4'b0011;
            default: mask = 4'b1111;
        endcase
    end

    // reg_data_sel mux
    always_comb begin
        case (reg_data_sel)
            3'b000:  reg_data = alu_res;
            3'b001:  reg_data = imm_pc;
            3'b010:  reg_data = imm;
            3'b011:  reg_data = pc4;
            default: reg_data = csr_out;
        endcase
    end

    // data_lb mux
    always_comb begin
        case (alu_res[1:0])
            2'b00:   data_lb = mem_rd_data[7:0];
            2'b01:   data_lb = mem_rd_data[15:8];
            2'b10:   data_lb = mem_rd_data[23:16];
            default: data_lb = mem_rd_data[31:24];
        endcase
    end

    // load_sel mux
    always_comb begin
        case (load_sel)
            2'b00:   mem_data = data_ext_lb;
            2'b01:   mem_data = data_ext_lh;
            default: mem_data = mem_rd_data;
        endcase
    end

endmodule

`endif // __FILE_CPU_V