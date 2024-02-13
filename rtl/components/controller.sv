`ifndef __FILE_CONTROLLER_V
`define __FILE_CONTROLLER_V

`define EXCEPTIONCODE_ILLEGAL_INSTR 2
`define EXCEPTIONCODE_BREAKPOINT 3

`define ILLEGAL_INSTR_HANDLER                \
    exception = 1;                           \
    exc_code = `EXCEPTIONCODE_ILLEGAL_INSTR;

(* dont_touch = "yes" *) module module_controller (
    input  logic [31:0] instruction,
    input  logic [31:0] mem_addr,
    input  logic        alu_zero,
    input  logic        clk,
    input  logic        reset,
    input  logic        interrupt,

    output logic [3:0]  alu_ctrl,
    output logic [1:0]  alu_src1,
    output logic [1:0]  alu_src2,
    output logic        alu_to_pc,
    output logic        branch,
    output logic [1:0]  load_sel,
    output logic [1:0]  mask_sel,
    output logic        mem_to_reg,
    output logic        mem_we,
    output logic [2:0]  reg_data_sel,
    output logic        reg_we,
    output logic        rs2_shift_sel,
    output logic        uext,
    output logic        csr_we,
    output logic        mret,
    output logic        exception,
    output logic [30:0] exc_code
);

    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [4:0] rs1   ;
    logic [4:0] uimm  ;
    logic [4:0] rs2   ;
    logic [4:0] rd    ;
    logic [6:0] opcode;
    logic [1:0] privilege_level;

    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];
    assign rs1    = instruction[19:15];
    assign uimm   = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign rd     = instruction[11:7];
    assign opcode = instruction[6:0];

    // store current privilege level
    // only two (machine and user) are supported for now
    always_ff @(posedge clk) begin
        if (mret)
            privilege_level = 2'b00; // user mode
        else if (reset || interrupt || exception)
            privilege_level = 2'b11; // machine mode
    end

    // decode instructions and set control signals
    always_comb begin
        // init control signals to default values
        alu_ctrl      = 4'b0001;
        alu_src1      = 0;
        alu_src2      = 0;
        alu_to_pc     = 0;
        branch        = 0;
        load_sel      = funct3[1:0];
        mask_sel      = funct3[1:0];
        mem_to_reg    = 0;
        mem_we        = 0;
        reg_data_sel  = 0;
        reg_we        = 0;
        rs2_shift_sel = funct3[0];
        uext          = funct3[2];
        csr_we        = 0;
        mret          = 0;
        exception     = 0;
        exc_code      = 0;

        casez (opcode[6:2]) // omit the lowest two bits of opcode - they are always 11
            5'b01100: begin // R-type
                // set matching signals
                reg_we = 1;

                case (funct3)
                    3'b000: alu_ctrl = {2'b00, funct7[5], ~funct7[5]}; // ADD or SUB
                    3'b001: alu_ctrl = 4'b0111; // SLL
                    3'b010: alu_ctrl = 4'b1010; // SLT
                    3'b011: alu_ctrl = 4'b1011; // SLTU
                    3'b100: alu_ctrl = 4'b0110; // XOR
                    3'b101: alu_ctrl = {3'b100, funct7[5]}; // SRA or SRL
                    3'b110: alu_ctrl = 4'b0101; // OR
                    3'b111: alu_ctrl = 4'b0011; // AND
                endcase
            end
            
            5'b00?00: begin // I-type without JALR
                // set matching signals
                alu_src2 = 2'b01;
                reg_we   = 1;

                if (opcode[4]) begin // immediate register-register
                    case (funct3)
                        3'b000: alu_ctrl = 4'b0001; // ADDI
                        3'b001: alu_ctrl = 4'b0111; // SLLI
                        3'b010: alu_ctrl = 4'b1010; // SLTI
                        3'b011: alu_ctrl = 4'b1011; // SLTIU
                        3'b100: alu_ctrl = 4'b0110; // XORI
                        3'b101: alu_ctrl = {3'b100, funct7[5]}; // SRAI or SRLI
                        3'b110: alu_ctrl = 4'b0101; // ORI
                        3'b111: alu_ctrl = 4'b0011; // ANDI
                    endcase
                end else begin // memory-register
                    mem_to_reg = 1;
                end
            end

            5'b11001: begin // JALR
                alu_src2     = 2'b01;
                alu_to_pc    = 1;
                branch       = 1;
                reg_data_sel = 3'b011;
                reg_we       = 1;
            end

            5'b01000: begin // S-type
                alu_src2 = 2'b01;
                mem_we   = 1;
            end

            5'b11000: begin // B-type
                case (funct3)
                    3'b000: begin // BEQ
                        alu_ctrl = 4'b0010;
                        branch   = alu_zero;
                    end
                    3'b001: begin // BNE
                        alu_ctrl = 4'b0010;
                        branch   = ~alu_zero;
                    end
                    3'b100: begin // BLT
                        alu_ctrl = 4'b1010;
                        branch   = ~alu_zero;
                    end
                    3'b101: begin // BGE
                        alu_ctrl = 4'b1010;
                        branch   = alu_zero;
                    end
                    3'b110: begin // BLTU
                        alu_ctrl = 4'b1011;
                        branch   = ~alu_zero;
                    end
                    3'b111: begin // BGEU
                        alu_ctrl = 4'b1011;
                        branch   = alu_zero;
                    end
                    default: begin
                        `ILLEGAL_INSTR_HANDLER
                    end
                endcase
            end

            5'b0?101: begin // U-type
                reg_data_sel = opcode[5] ? 3'b010 : 3'b001;
                reg_we       = 1;
            end

            5'b11011: begin // J-type
                branch       = 1;
                reg_data_sel = 3'b011;
                reg_we       = 1;
            end

            5'b00011: begin end // FENCE or Zifencei standard extension

            5'b11100: begin // SYSTEM: ECALL, EBREAK, MRET or Zicsr standard extension
                case (funct3)
                    3'b000: begin
                        if (funct7[3]) begin // SRET, MRET
                            if (funct7[4]) begin // MRET
                                if (privilege_level == 2'b11) begin
                                    // TODO throw exception
                                end else begin
                                    branch = 1;
                                    mret   = 1;
                                end
                            end else begin // SRET
                                `ILLEGAL_INSTR_HANDLER
                            end
                        end else begin
                            if (rs2[0]) begin // EBREAK
                                exception = 1;
                                exc_code  = `EXCEPTIONCODE_BREAKPOINT;
                            end else begin // ECALL
                                exception = 1;
                                exc_code  = { { 28{1'b0} }, 2'b10, privilege_level }; // ECALL exception code = 8 + privilege level.
                            end
                        end
                    end
                    3'b001: begin // CSRRW
                        alu_ctrl     = 0;
                        reg_data_sel = 3'b100;
                        reg_we       = 1;
                        csr_we       = 1;
                    end
                    3'b010: begin // CSRRS
                        alu_ctrl     = 4'b0101;
                        alu_src2     = 2'b10;
                        reg_data_sel = 3'b100;
                        reg_we       = 1;
                        csr_we       = rs1 != 0;
                    end
                    3'b011: begin // CSRRC
                        alu_ctrl     = 4'b0100;
                        alu_src2     = 2'b10;
                        reg_data_sel = 3'b100;
                        reg_we       = 1;
                        csr_we       = rs1 != 0;
                    end
                    3'b100: begin
                       `ILLEGAL_INSTR_HANDLER 
                    end // reserved
                    3'b101: begin // CSRRWI
                        alu_ctrl     = 0;
                        alu_src1     = 1;
                        alu_src2     = 2'b10;
                        reg_data_sel = 3'b100;
                        reg_we       = 1;
                        csr_we       = 1;
                    end
                    3'b110: begin // CSRRSI
                        alu_ctrl     = 4'b0101;
                        alu_src1     = 1;
                        alu_src2     = 2'b10;
                        reg_data_sel = 3'b100;
                        reg_we       = 1;
                        csr_we       = uimm != 0;
                    end
                    3'b111: begin // CSRRCI
                        alu_ctrl     = 4'b0100;
                        alu_src1     = 1;
                        alu_src2     = 2'b10;
                        reg_data_sel = 3'b100;
                        reg_we       = 1;
                        csr_we       = uimm != 0;
                    end
                endcase
            end

            default: begin
                `ILLEGAL_INSTR_HANDLER
            end
        endcase
    end

endmodule

`endif // __FILE_CONTROLLER_V