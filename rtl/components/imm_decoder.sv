`ifndef __FILE_IMMDECODER_V
`define __FILE_IMMDECODER_V

(* dont_touch = "yes" *) module module_imm_decoder (
    input  logic [31:0] instruction, // instruction to get the immediate from

    output logic [31:0] imm          // result immediate
);

    logic [2:0] funct3;
    logic [6:0] opcode;
    logic [4:0] rs1;

    assign funct3 = instruction[14:12];
    assign opcode = instruction[6:0];
    assign rs1    = instruction[19:15];

    always_comb begin
        casez (opcode[6:2]) // omit the lowest two bits of opcode - they are always 11
            5'b00?00: begin // I-type without JALR
                if (opcode[4] && funct3[1:0] == 2'b01) begin // SLLI, SRLI or SRAI instruction
                    imm[4:0]  = instruction[24:20];
                    imm[31:5] = 0;
                end else begin
                    imm[11:0]  = instruction[31:20];
                    imm[31:12] = { 20{instruction[31]} };
                end
            end

            5'b11001: begin // JALR
                imm[11:0]  = instruction[31:20];
                imm[31:12] = { 20{instruction[31]} };
            end

            5'b01000: begin // S-type
                imm[4:0]   = instruction[11:7];
                imm[11:5]  = instruction[31:25];
                imm[31:12] = { 20{instruction[31]} };
            end

            5'b11000: begin // B-type
                imm[0]     = 0;
                imm[4:1]   = instruction[11:8];
                imm[10:5]  = instruction[30:25];
                imm[11]    = instruction[7];
                imm[12]    = instruction[31];
                imm[31:13] = { 19{instruction[31]} };
            end

            5'b0?101: begin // U-type
                imm[11:0]  = 0;
                imm[31:12] = instruction[31:12];
            end

            5'b11011: begin // J-type
                imm[0]     = 0;
                imm[10:1]  = instruction[30:21];
                imm[11]    = instruction[20];
                imm[19:12] = instruction[19:12];
                imm[20]    = instruction[31];
                imm[31:21] = { 11{instruction[31]} };
            end

            default: imm = { { 27{1'b0} }, rs1 }; // CSRRWI, CSRRSI or CSRRCI
        endcase
    end

endmodule

`endif // __FILE_IMMDECODER_V