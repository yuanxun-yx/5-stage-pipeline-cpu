`timescale 1ns / 1ps

// ISA: RISC-V32
// controller of single-cycle CPU
// Havard Architecture
// pure combinational circuit

// implemented instructions:
//
// - Integer Computational Instructions
//   - Integer Register-Immediate Instructions
//     - addi, slti[u]
//     - andi, ori, xori
//     - slli, srli, srai
//     - lui, auipc
//   - Integer Register-Register Operations
//     - add, slt[u]
//     - and, or, xor
//     - sll, srl
//     - sub, sra
//   - NOP Instruction
// - Control Transfer Instructions
//   - Unconditional Jumps
//     - jal
//     - jalr
//   - Conditional Branches
//     - beq, bne
//     - blt[u]
//     - bge[u]
// - Load and Store Instructions
//     - lw, sw

module controller
    (
     output reg reg_write,
     output reg [2:0] pc_source,
     output reg alu_source_a,
     output reg alu_source_b,
     output reg [1:0] data_to_reg,
     output reg [3:0] alu_operation,
     output reg mem_write, mem_read,
     
     input wire [31:0] instruction
    );

    // symbolic operation code declaration
    `include "symbolic_control_signals.vh"

    // RISC-V opcode and funct3 declaration
    `include "riscv_instruction_set.vh"

    // signal declaration
    wire [6:0] opcode;
    wire [6:0] funct7;
    wire [2:0] funct3;

    // body: output combinational logic
    
    assign opcode = instruction[6:0];  
    assign funct7 = instruction[31:25];
    assign funct3 = instruction[14:12];
    
    always @*
        begin
            // default values
            // (incorrect instruction)
            reg_write = 1'b0;
            mem_read = 1'b0;
            mem_write = 1'b0;

            pc_source = pc_source_unknown;
            alu_source_a = alu_source_a_unknown;
            alu_source_b = alu_source_b_unknown;
            data_to_reg = data_to_reg_unknown;
            alu_operation = alu_operation_unknown;

            case (opcode)

                // integer register-register operations
                opcode_op:
                    begin
                        reg_write = 1'b1;
                        pc_source = pc_source_pc_plus_4;
                        alu_source_a = alu_source_a_rs1;
                        alu_source_b = alu_source_b_rs2;
                        data_to_reg = data_to_reg_alu_result;
                        
                        // the value of alu_operation can be expressed in this way:
                        // alu_operation = {funct7[5], funct3};
                        // however, for better code readability and expandability,
                        // it's written in this way:
                        case (funct7)
                            funct7_0:
                                case (funct3)
                                    funct3_add_sub: alu_operation = alu_operation_add;
                                    funct3_sll: alu_operation = alu_operation_sll;
                                    funct3_slt: alu_operation = alu_operation_slt;
                                    funct3_sltu: alu_operation = alu_operation_sltu;
                                    funct3_xor: alu_operation = alu_operation_xor;
                                    funct3_srl_sra: alu_operation = alu_operation_srl;
                                    funct3_or: alu_operation = alu_operation_or;
                                    funct3_and: alu_operation = alu_operation_and;
                                endcase
                            funct7_1: 
                                case (funct3)
                                    funct3_add_sub: alu_operation = alu_operation_sub;
                                    funct3_srl_sra: alu_operation = alu_operation_sra;
                                endcase
                        endcase
                    end

                // integer register-immediate operations
                opcode_op_imm:
                    begin
                        reg_write = 1'b1;
                        pc_source = pc_source_pc_plus_4;
                        alu_source_a = alu_source_a_rs1;
                        alu_source_b = alu_source_b_imm;
                        data_to_reg = data_to_reg_alu_result;

                        // ALMOST the same as above
                        case (funct3)
                                funct3_add_sub: alu_operation = alu_operation_add;
                                funct3_sll: alu_operation = alu_operation_sll;
                                funct3_slt: alu_operation = alu_operation_slt;
                                funct3_sltu: alu_operation = alu_operation_sltu;
                                funct3_xor: alu_operation = alu_operation_xor;
                                funct3_srl_sra: 
                                    case (funct7)
                                        funct7_0: alu_operation = alu_operation_srl;
                                        funct7_1: alu_operation = alu_operation_sra;
                                    endcase
                                funct3_or: alu_operation = alu_operation_or;
                                funct3_and: alu_operation = alu_operation_and;
                        endcase
                    end

                // load upper immediate
                opcode_lui:
                    begin
                        reg_write = 1'b1;
                        pc_source = pc_source_pc_plus_4;
                        data_to_reg = data_to_reg_upper_imm;
                    end

                // add upper immediate to PC
                opcode_auipc:
                    begin
                        reg_write = 1'b1;
                        pc_source = pc_source_pc_plus_4;
                        alu_source_a = alu_source_a_pc;
                        alu_source_b = alu_source_b_imm;
                        data_to_reg = data_to_reg_alu_result;
                        alu_operation = alu_operation_add;
                    end

                // unconditional jumps
                opcode_jal:
                    begin
                        reg_write = 1'b1;
                        pc_source = pc_source_pc_plus_offset;
                        data_to_reg = data_to_reg_pc_plus_4;
                    end

                opcode_jalr:
                    begin
                        reg_write = 1'b1;
                        pc_source = pc_source_alu_result;
                        alu_source_a = alu_source_a_rs1;
                        alu_source_b = alu_source_b_imm;
                        data_to_reg = data_to_reg_pc_plus_4;
                        alu_operation = alu_operation_add;
                    end

                // conditional branches
                opcode_branch:
                    case (funct3)
                        funct3_beq: 
                            begin
                                pc_source = pc_source_branch_zero;
                                alu_source_a = alu_source_a_rs1;
                                alu_source_b = alu_source_b_rs2;
                                alu_operation = alu_operation_sub;
                            end 
                        funct3_bne: 
                            begin
                                pc_source = pc_source_branch_not_zero;
                                alu_source_a = alu_source_a_rs1;
                                alu_source_b = alu_source_b_rs2;
                                alu_operation = alu_operation_sub;
                            end 
                        funct3_blt:
                            begin
                                pc_source = pc_source_branch_not_zero;
                                alu_source_a = alu_source_a_rs1;
                                alu_source_b = alu_source_b_rs2;
                                alu_operation = alu_operation_slt;
                            end
                        funct3_bge:
                            begin
                                pc_source = pc_source_branch_zero;
                                alu_source_a = alu_source_a_rs1;
                                alu_source_b = alu_source_b_rs2;
                                alu_operation = alu_operation_slt;
                            end
                        funct3_bltu:
                            begin
                                pc_source = pc_source_branch_not_zero;
                                alu_source_a = alu_source_a_rs1;
                                alu_source_b = alu_source_b_rs2;
                                alu_operation = alu_operation_sltu;
                            end
                        funct3_bgeu:
                            begin
                                pc_source = pc_source_branch_zero;
                                alu_source_a = alu_source_a_rs1;
                                alu_source_b = alu_source_b_rs2;
                                alu_operation = alu_operation_sltu;
                            end
                    endcase

                // load instructions
                opcode_load:
                    case (funct3)
                        funct3_lw: 
                            begin
                                reg_write = 1'b1;
                                mem_read = 1'b1;
                                pc_source = pc_source_pc_plus_4;
                                alu_source_a = alu_source_a_rs1;
                                alu_source_b = alu_source_b_imm;
                                data_to_reg = data_to_reg_memory_data;
                                alu_operation = alu_operation_add;
                            end 
                    endcase

                // store instructions
                opcode_store:
                    case (funct3)
                        funct3_sw: 
                            begin
                                mem_write = 1'b1;
                                pc_source = pc_source_pc_plus_4;
                                alu_source_a = alu_source_a_rs1;
                                alu_source_b = alu_source_b_imm;
                                alu_operation = alu_operation_add;
                            end 
                    endcase
            endcase
        end

endmodule
