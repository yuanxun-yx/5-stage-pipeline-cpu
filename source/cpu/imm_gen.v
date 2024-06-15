// generate imm 
// according to opcode
module imm_gen
    (
     input wire [31:0] instruction,
     output reg [31:0] imm
    );
    
    // symbolic opcode declaration
    `include "riscv_instruction_set.vh"

    // sign-extended immediate for S-type and instruction
    //
    // S-type format:
    //      31:25       24:20  19:15  14:12        11:7        6:0
    // immediate[11:5]   rs2    rs1   funct3  immediate[4:0]  opcode
    //
    // I-type format:
    //      31:20       19:15  14:12   11:7    6:0
    // immediate[11:0]   rs1   funct3   rd    opcode
    //
    // U-type format:
    //      31:12       11:7     6:0
    // immediate[11:0]   rd    opcode
    //
    // instruction will be treated as S-type if it's B-type
    // because if it's B-type, it must be treated as S-type so that shift_left_1 
    // module can work correctly
    //
    // the transformation from U type to J type is similar
    always @(*)
        begin
            imm = 32'hxxxx_xxxx;
            case (instruction[6:0])
                opcode_op_imm, opcode_load: imm = {{20{instruction[31]}}, instruction[31:20]};
                opcode_store, opcode_branch, opcode_jalr: imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
                opcode_lui, opcode_auipc, opcode_jal: imm = {instruction[31:12], 12'b0};
            endcase
        end

endmodule
