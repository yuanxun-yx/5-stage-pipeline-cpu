// shift given imm left for 1 bit
// according to opcode
module shift_left_1
    (
     input wire [6:0] opcode,
     input wire [31:0] imm,
     output reg [31:0] offset
    );
    
    // symbolic opcode declaration
    `include "riscv_instruction_set.vh"

    // branch offset (relative to PC, not PC + 4) for SB-type instruction
    //
    // B-type format:
    //        31:25        24:20  19:15   14:12        11:7          6:0
    // immediate[12,10:5]   rs2    rs1   funct3  immediate[4:1,11]  opcode
    //
    // this detail is an ingenious design of RISC-V ISA
    // say, if an instruction is B-type, sign_ext_imm = {{20{imm[12]}, imm[12,10:5], imm[4:1,11]}} 
    // according to imm_gen module
    // then in order to get correct answer, shift_left_1 module only have to exchange imm[11] and imm[12],
    // and replace LSB with 0
    // the design of RISC-V allows the hardware to avoid shifting operation
    // the reuse of sign_ext_imm is perticularly useful in pipelined design
    //
    // the transformation from U to J type is similar
    always @*
        begin
            offset = 32'hxxxx_xxxx;
            case (opcode)
                opcode_branch: offset = {imm[31:12], imm[0], imm[10:1], 1'b0};
                opcode_jal: offset = {{12{imm[31]}}, imm[19:12], imm[20], imm[30:21], 1'b0};
            endcase
        end

endmodule
