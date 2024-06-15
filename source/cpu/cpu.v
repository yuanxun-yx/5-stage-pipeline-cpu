`timescale 1ns / 1ps
`include "debug.vh"

// ISA: RISC-V32
// datapath of single-cycle CPU
// Havard Architecture

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

module cpu
    (
     input wire clk,
     input wire reset
     // debug
     `ifdef DEBUG_MODE
     ,input wire [6:0] debug_addr,
     output wire [31:0] debug_data
     `endif
    );
    
    // symbolic operation code declaration
    `include "symbolic_control_signals.vh"

    // RISC-V opcode and funct3 declaration
    `include "riscv_instruction_set.vh"

    // signal declaration

    // IF: instruction fetch
    // PC register
    (* mark_debug = "true" *)reg [31:0] pc_reg;
    // PC for next instruction
    reg [31:0] next_pc;
    // binary instruction from instruction memory 
    wire [31:0] instruction;
    // default next PC
    wire [31:0] pc_plus_4;
    // flush: IR = nop
    wire if_flush;

    // IF/ID pipeline register
    // data signals
    reg [31:0] if_id_pc_reg, if_id_pc_plus_4_reg, if_id_inst_reg;

    // ID: instruction decode
    // signals for controller
    wire ctrl_mem_read, ctrl_mem_write;
    wire ctrl_reg_write , ctrl_alu_source_a, ctrl_alu_source_b;
    wire [2:0] ctrl_pc_source;
    wire [1:0] ctrl_data_to_reg;
    wire [3:0] ctrl_alu_operation;
    // signals for dataflow
    // data read from register file
    wire [31:0] rd_data_a, rd_data_b;
    // 32-bit sign-extended immediate number for S-type and I-type instruction
    wire [31:0] sign_ext_imm;
    // branch offset for B-type instruction 
    wire [31:0] offset;
    wire [31:0] pc_plus_offset;
    // assign rs1/rs2 zero if it doesn't exist
    reg [4:0] id_ex_rs1_next, id_ex_rs2_next;
    // flush: ID/EX control = 0
    wire id_flush, pc_alter_id_flush;

    // ID/EX pipeline register
    // control signals register
    // - EX
    reg id_ex_ex_alu_source_a_reg, id_ex_ex_alu_source_b_reg;
    reg [3:0] id_ex_ex_alu_operation_reg;
    // - MEM
    reg id_ex_mem_mem_write_reg, id_ex_mem_mem_read_reg;
    reg [2:0] id_ex_mem_pc_source_reg;
    // - WB
    reg id_ex_wb_reg_write_reg;
    reg [1:0] id_ex_wb_data_to_reg_reg;
    // data signals
    reg [31:0] id_ex_pc_reg, id_ex_pc_plus_4_reg, id_ex_pc_plus_offset_reg;
    reg [31:0] id_ex_rd_data_a_reg, id_ex_rd_data_b_reg, id_ex_imm_reg;
    reg [4:0] id_ex_rd_reg, id_ex_rs1_reg, id_ex_rs2_reg;
    
    // EX: execution
    // operands for ALU
    reg [31:0] operand_a_original, operand_b_original;
    reg [31:0] operand_a, operand_b;
    wire [31:0] alu_result;
    reg [31:0] ex_mem_write_data_next;
    wire branch_taken;
    // flush: EX/MEM control = 0
    wire ex_flush;

    // EX/MEM pipeline register
    // control signals
    // - MEM
    reg ex_mem_mem_mem_write_reg, ex_mem_mem_mem_read_reg;
    reg [2:0] ex_mem_mem_pc_source_reg;
    // - WB
    reg ex_mem_wb_reg_write_reg;
    reg [1:0] ex_mem_wb_data_to_reg_reg;
    // data signals
    reg [31:0] ex_mem_alu_result_reg, ex_mem_rd_data_b_reg, 
               ex_mem_write_data_reg, ex_mem_pc_plus_offset_reg;
    reg [4:0] ex_mem_rd_reg;

    // MEM: memory access
    wire [31:0] memory_data;
    // select ex_mem_write_data / alu_result as write_data
    reg [31:0] mem_wb_write_data_next;
    // alu_result == 0
    wire zero;

    // MEM/WB pipeline regiser
    // control signals
    // - WB
    reg mem_wb_wb_reg_write_reg;
    reg [1:0] mem_wb_wb_data_to_reg_reg;
    // data signals
    reg [31:0] mem_wb_mem_data_reg, mem_wb_write_data_reg;
    reg [4:0] mem_wb_rd_reg;

    // WB: write back
    // write data for register file
    reg [31:0] write_data;

    // data hazard
    // forwarding unit
    reg [1:0] forward_alu_a, forward_alu_b;
    // hazard detection unit
    wire hazard_id_flush, pc_write, if_id_write;
    wire alu_operand_stall;

    // body
    
    // ========================================================================
    // IF: instruction fetch
    // ========================================================================

    // the program counter register, abbreviated as PC
    always @(negedge clk, posedge reset)
        if (reset)
            pc_reg <= 32'b0;
        else if (pc_write)
            pc_reg <= next_pc;

    // 32-bit 4 adder
    assign pc_plus_4 = pc_reg + 4;
    
    // next PC
    always @*
        begin
            // default: next instuction
            next_pc = pc_plus_4;
            
            // check MEM first, because it's the foremost one
            // if branch at MEM stage is taken
            if (branch_taken)
                next_pc = ex_mem_pc_plus_offset_reg;
            // jalr at MEM stage
            else if (ex_mem_mem_pc_source_reg == pc_source_alu_result)
                next_pc = {ex_mem_alu_result_reg[31:1], 1'b0};
            // then check jal at ID stage
            else if (ctrl_pc_source == pc_source_pc_plus_offset)
                next_pc = pc_plus_offset;
        end
            
    // instruction memory
    rom
        #(
          .ADDR_WIDTH(10),
          .INIT_FILE("text.mem")
        )
    inst_mem_unit
        (
         .clk(clk),
         .addr(pc_reg[11:2]),
         .data(instruction)
        );

    // here we assume that branch not taken,
    // thus if it's taken, we need to flush a bubble
    //    
    // other instructions that changes PC also causes a if_flush,
    // because it will take serveral cycles to compute next PC
    // ID: pc_plus_offset (jal)
    // MEM: branches, alu_result (jalr)
    assign if_flush = (ctrl_pc_source == pc_source_pc_plus_offset) ||
                      (ex_mem_mem_pc_source_reg == pc_source_alu_result) ||
                      branch_taken;

    // ========================================================================
    // IF/ID pipeline register
    // ========================================================================

    always @(negedge clk, posedge reset)
        if (reset)
            begin
                // data signals
                if_id_inst_reg <= nop;
                if_id_pc_reg <= 32'b0;
                if_id_pc_plus_4_reg <= 32'b0;
            end
        else if (if_id_write)
            begin
                // data signals
                if (if_flush) if_id_inst_reg <= nop;
                else if_id_inst_reg <= instruction;
                if_id_pc_reg <= pc_reg;
                if_id_pc_plus_4_reg <= pc_plus_4;
            end
        
    // ========================================================================
    // ID: instruction decode
    // ========================================================================
    
    // controller
    controller controller_unit
        (
         .instruction(if_id_inst_reg),

         .reg_write(ctrl_reg_write),
         .pc_source(ctrl_pc_source),
         .alu_source_a(ctrl_alu_source_a),
         .alu_source_b(ctrl_alu_source_b),
         .data_to_reg(ctrl_data_to_reg),
         .alu_operation(ctrl_alu_operation),
         .mem_write(ctrl_mem_write), .mem_read(ctrl_mem_read)
        );
    
    // generate imm
    imm_gen imm_gen_unit
        (
         .instruction(if_id_inst_reg),
         .imm(sign_ext_imm)
        );

    // generate offset
    shift_left_1 shift_left_1_unit
        (
         .opcode(if_id_inst_reg[6:0]),
         .imm(sign_ext_imm),
         .offset(offset)
        );

    // 32-bit adder
    assign pc_plus_offset = if_id_pc_reg + offset;


    // the register file containing 32 registers for CPU
    reg_file reg_file_unit
        (
         .clk(clk),
         .reset(reset),

         .reg_write(mem_wb_wb_reg_write_reg),

         .read_addr_a(if_id_inst_reg[19:15]),    // rs1
         .read_addr_b(if_id_inst_reg[24:20]),    // rs2
         .read_data_a(rd_data_a),
         .read_data_b(rd_data_b),
         
         .write_addr(mem_wb_rd_reg),      // rd
         .write_data(write_data)
         
         `ifdef DEBUG_MODE
         // debug
         ,.debug_addr(debug_addr),
         .debug_data(debug_data)
         `endif
        );

    // if instruction doesn't have rs1/rs2 field,
    // they should be assigned zero for forwarding unit
    always @*
        case (if_id_inst_reg[6:0])
            opcode_jalr, opcode_branch, opcode_load, 
            opcode_store, opcode_op_imm, opcode_op:
                id_ex_rs1_next = if_id_inst_reg[19:15];
            default: 
                id_ex_rs1_next = 5'b0;
        endcase
    always @*
        case (if_id_inst_reg[6:0])
            opcode_branch, opcode_store, opcode_op:
                id_ex_rs2_next = if_id_inst_reg[24:20];
            default: 
                id_ex_rs2_next = 5'b0;
        endcase

    // here we assume that branch not taken,
    // thus if it's taken, we need to flush a bubble
    //    
    // other instructions that changes PC also causes a if_flush,
    // because it will take serveral cycles to compute next PC
    // MEM: branches, alu_result (jalr)
    assign pc_alter_id_flush = (ex_mem_mem_pc_source_reg == pc_source_alu_result) ||
                               branch_taken;

    assign id_flush = pc_alter_id_flush | hazard_id_flush;
    
    // ========================================================================
    // ID/EX pipeline register
    // ========================================================================
    
    always @(negedge clk, posedge reset)
        if (reset)
            begin
                // control signals
                // - EX
                id_ex_ex_alu_source_a_reg <= 1'b0;
                id_ex_ex_alu_source_b_reg <= 1'b0;
                id_ex_ex_alu_operation_reg <= 4'b0;
                // - MEM
                id_ex_mem_mem_write_reg <= 1'b0;
                id_ex_mem_mem_read_reg <= 1'b0;
                id_ex_mem_pc_source_reg <= 3'b0;
                // - WB
                id_ex_wb_reg_write_reg <= 1'b0;
                id_ex_wb_data_to_reg_reg <= 2'b0;
                // data signals
                id_ex_pc_reg <= 32'b0;
                id_ex_pc_plus_4_reg <= 32'b0;
                id_ex_pc_plus_offset_reg <= 32'b0;
                id_ex_rd_data_a_reg <= 32'b0;
                id_ex_rd_data_b_reg <= 32'b0;
                id_ex_imm_reg <= 32'b0;
                id_ex_rd_reg <= 5'b0;
                id_ex_rs1_reg <= 5'b0;
                id_ex_rs2_reg <= 5'b0;
            end
        else
            begin
                // control signals
                if (id_flush)
                    begin
                        // - EX
                        id_ex_ex_alu_source_a_reg <= 1'b0;
                        id_ex_ex_alu_source_b_reg <= 1'b0;
                        id_ex_ex_alu_operation_reg <= 4'b0;
                        // - MEM
                        id_ex_mem_mem_write_reg <= 1'b0;
                        id_ex_mem_mem_read_reg <= 1'b0;
                        id_ex_mem_pc_source_reg <= 3'b0;
                        // - WB
                        id_ex_wb_reg_write_reg <= 1'b0;
                        id_ex_wb_data_to_reg_reg <= 2'b0;
                    end
                else
                    begin
                        // - EX
                        id_ex_ex_alu_source_a_reg <= ctrl_alu_source_a;
                        id_ex_ex_alu_source_b_reg <= ctrl_alu_source_b;
                        id_ex_ex_alu_operation_reg <= ctrl_alu_operation;
                        // - MEM
                        id_ex_mem_mem_write_reg <= ctrl_mem_write;
                        id_ex_mem_mem_read_reg <= ctrl_mem_read;
                        id_ex_mem_pc_source_reg <= ctrl_pc_source;
                        // - WB
                        id_ex_wb_reg_write_reg <= ctrl_reg_write;
                        id_ex_wb_data_to_reg_reg <= ctrl_data_to_reg;
                    end
                // data signals
                id_ex_pc_reg <= if_id_pc_reg;
                id_ex_pc_plus_4_reg <= if_id_pc_plus_4_reg;
                id_ex_pc_plus_offset_reg <= pc_plus_offset;
                id_ex_rd_data_a_reg <= rd_data_a;
                id_ex_rd_data_b_reg <= rd_data_b;
                id_ex_imm_reg <= sign_ext_imm;
                id_ex_rd_reg <= if_id_inst_reg[11:7];
                id_ex_rs1_reg <= id_ex_rs1_next;
                id_ex_rs2_reg <= id_ex_rs2_next;
            end

    // ========================================================================
    // EX: execution
    // ========================================================================
    
    // 32-bit 2-to-1 MUX
    // selects the first operand of ALU
    always @*
        case(id_ex_ex_alu_source_a_reg)
            // for computational instructions
            alu_source_a_rs1: operand_a_original = id_ex_rd_data_a_reg;
            // for auipc
            alu_source_a_pc: operand_a_original = id_ex_pc_reg;
			// default value
			default: write_data = 32'hxxxx_xxxx;
        endcase

    // 32-bit 2-to-1 MUX
    // selects the second operand of ALU
    always @*
        case(id_ex_ex_alu_source_b_reg)
            // for register-register computation instructions
            alu_source_b_rs2: operand_b_original = id_ex_rd_data_b_reg;
            // base addressing for store and load instructions
            // integer register-immediate instructions
            alu_source_b_imm: operand_b_original = id_ex_imm_reg;
            // default value
            default: operand_b_original = 32'hxxxx_xxxx;
        endcase

    // forwarding mux

    // operand a forwarding mux
    always @*
        case(forward_alu_a)
            // original operand a
            forward_alu_a_original: operand_a = operand_a_original;
            // WB
            forward_alu_a_wb: operand_a = write_data;
            // MEM
            forward_alu_a_mem: operand_a = mem_wb_write_data_next;
            // default value
            default: operand_a = 32'hxxxx_xxxx;
        endcase

    // operand b forwarding mux
    always @*
        case(forward_alu_b)
            // original operand b
            forward_alu_b_original: operand_b = operand_b_original;
            // WB
            forward_alu_b_wb: operand_b = write_data;
            // MEM
            forward_alu_b_mem: operand_b = mem_wb_write_data_next;
            // default value
            default: operand_b = 32'hxxxx_xxxx;
        endcase
    
    // arithmetic and logical unit, abbreviated as ALU
    alu alu_unit
        (
         .a(operand_a),
         .b(operand_b),
         
         .alu_operation(id_ex_ex_alu_operation_reg),
         .result(alu_result)
        );

    // selected in advance for forwarding
    always @*
        case (id_ex_wb_data_to_reg_reg)
            data_to_reg_upper_imm: ex_mem_write_data_next = id_ex_imm_reg;
            data_to_reg_pc_plus_4: ex_mem_write_data_next = id_ex_pc_plus_4_reg; 
            default: ex_mem_write_data_next = 32'hxxxx_xxxx;
        endcase

    // here we assume that branch not taken,
    // thus if it's taken, we need to flush a bubble
    //    
    // other instructions that changes PC also causes a if_flush,
    // because it will take serveral cycles to compute next PC
    // MEM: branches, alu_result (jalr)
    assign ex_flush = (ex_mem_mem_pc_source_reg == pc_source_alu_result) ||
                      branch_taken;

    // ========================================================================
    // EX/MEM pipeline register
    // ========================================================================
    
    always @(negedge clk, posedge reset)
        if (reset)
            begin
                // control signals
                // - MEM
                ex_mem_mem_mem_write_reg <= 1'b0;
                ex_mem_mem_mem_read_reg <= 1'b0;
                ex_mem_mem_pc_source_reg <= 3'b0;
                // - WB
                ex_mem_wb_reg_write_reg <= 1'b0;
                ex_mem_wb_data_to_reg_reg <= 2'b0;
                // data signals
                ex_mem_alu_result_reg <= 32'b0;
                ex_mem_rd_data_b_reg <= 32'b0;
                ex_mem_write_data_reg <= 32'b0;
                ex_mem_rd_reg <= 5'b0;
                ex_mem_pc_plus_offset_reg <= 32'b0;
            end
        else
            begin
                // control signals
                if (ex_flush)
                    begin
                        // - MEM
                        ex_mem_mem_mem_write_reg <= 1'b0;
                        ex_mem_mem_mem_read_reg <= 1'b0;
                        ex_mem_mem_pc_source_reg <= 3'b0;
                        // - WB
                        ex_mem_wb_reg_write_reg <= 1'b0;
                        ex_mem_wb_data_to_reg_reg <= 2'b0;
                    end
                else
                    begin
                        // - MEM
                        ex_mem_mem_mem_write_reg <= id_ex_mem_mem_write_reg;
                        ex_mem_mem_mem_read_reg <= id_ex_mem_mem_read_reg;
                        ex_mem_mem_pc_source_reg <= id_ex_mem_pc_source_reg;
                        // - WB
                        ex_mem_wb_reg_write_reg <= id_ex_wb_reg_write_reg;
                        ex_mem_wb_data_to_reg_reg <= id_ex_wb_data_to_reg_reg;
                    end
                // data signals
                ex_mem_alu_result_reg <= alu_result;
                ex_mem_rd_data_b_reg <= id_ex_rd_data_b_reg;
                ex_mem_write_data_reg <= ex_mem_write_data_next;
                ex_mem_rd_reg <= id_ex_rd_reg;
                ex_mem_pc_plus_offset_reg <= id_ex_pc_plus_offset_reg;
            end

    // ========================================================================
    // MEM: memory access
    // ========================================================================

    // data memory
    ram
        #(
          .ADDR_WIDTH(10),
          .INIT_FILE("data.mem")
        )
    data_mem_unit
        (
         .clk(clk),
         .we(ex_mem_mem_mem_write_reg),
         .addr(ex_mem_alu_result_reg[11:2]),
         .din(ex_mem_rd_data_b_reg),
         .dout(memory_data)
        );

    // selected in advance for forwarding
    always @*
        case (ex_mem_wb_data_to_reg_reg)
            data_to_reg_pc_plus_4, data_to_reg_upper_imm: 
                mem_wb_write_data_next = ex_mem_write_data_reg;
            data_to_reg_alu_result: mem_wb_write_data_next = ex_mem_alu_result_reg; 
            default: mem_wb_write_data_next = 32'hxxxx_xxxx;
        endcase

    // compute zero here, because the delay of ALU is too long to fit zero in
    assign zero = (ex_mem_alu_result_reg == 0);

    // if branch shoule be taken
    assign branch_taken = (((ex_mem_mem_pc_source_reg == pc_source_branch_zero) && zero) ||
                ((ex_mem_mem_pc_source_reg == pc_source_branch_not_zero) && ~zero));

    // ========================================================================
    // MEM/WB pipeline register
    // ========================================================================
    
    always @(negedge clk, posedge reset)
        if (reset)
            begin
                // control signals
                // - WB
                mem_wb_wb_reg_write_reg <= 1'b0;
                mem_wb_wb_data_to_reg_reg <= 2'b0;
                // data signals
                mem_wb_mem_data_reg <= 32'b0;
                mem_wb_write_data_reg <= 32'b0;
                mem_wb_rd_reg = 5'b0;
            end
        else
            begin
                // control signals
                // - WB
                mem_wb_wb_reg_write_reg <= ex_mem_wb_reg_write_reg;
                mem_wb_wb_data_to_reg_reg <= ex_mem_wb_data_to_reg_reg;
                // data signals
                mem_wb_mem_data_reg <= memory_data;
                mem_wb_write_data_reg <= mem_wb_write_data_next;
                mem_wb_rd_reg <= ex_mem_rd_reg;
            end
    
    // ========================================================================
    // WB: write back
    // ========================================================================

    // 32-bit 4-to-1 MUX
    // selects the data written to register rd
    always @*
        case(mem_wb_wb_data_to_reg_reg)
            // all non-load instructions
            data_to_reg_alu_result, data_to_reg_upper_imm, 
            data_to_reg_pc_plus_4: 
                write_data = mem_wb_write_data_reg;
            // for load instructions
            data_to_reg_memory_data: write_data = mem_wb_mem_data_reg;
            // default value
            default: write_data = 32'hxxxx_xxxx;
        endcase

    // ========================================================================
    // Data Hazard
    // ========================================================================

    // forwarding unit
    always @*
        begin
            // default: no forwarding
            forward_alu_a = forward_alu_a_original;
            forward_alu_b = forward_alu_b_original;

            // forward the result from the preious instruction to
            // either input of ALU
            //
            // condition:
            // if the previous instruction is going to write to the register file,
            // and the write register number is not register 0,
            // and it matches the read register number of ALU inputs A or B

            // forward a
            // if this instruction doesn't have rs1 field, it'll be assigned
            // zero at ID stage
            // if it's not used, then forwarding SHOULD NOT proceed 
            // MEM hazard
            // consider data in MEM stage first, because this one is the newest one
            if (mem_wb_wb_reg_write_reg && (mem_wb_rd_reg != 5'b0) 
                && (mem_wb_rd_reg == id_ex_rs1_reg))
                forward_alu_a = forward_alu_a_wb;
            // EX hazard
            else if (ex_mem_wb_reg_write_reg && (ex_mem_rd_reg != 5'b0) 
                && (ex_mem_rd_reg == id_ex_rs1_reg))
                forward_alu_a = forward_alu_a_mem;
            
            // forward b (same as above)
            if (mem_wb_wb_reg_write_reg && (mem_wb_rd_reg != 5'b0) 
                && (mem_wb_rd_reg == id_ex_rs2_reg))
                forward_alu_b = forward_alu_b_wb;
            // EX hazard
            else if (ex_mem_wb_reg_write_reg && (ex_mem_rd_reg != 5'b0) 
                && (ex_mem_rd_reg == id_ex_rs2_reg))
                forward_alu_b = forward_alu_b_mem;

        end

    // harzard detection unit
    // insert bubbles
    // if the forwarded data isn't available at the BEGINNING of this cycle,
    // insert a bubble

    // ALU operand
    // if the instruction is a load (the only instruction that reads 
    // data is a load)
    // if the destination register field of the load in the EX stage 
    // matches either source register of the instruction in the ID stage 
    //
    // id_ex_rs1_next is used to avoid stalling for instructions that do not
    // even have a rs1 field
    assign alu_operand_stall = (id_ex_mem_mem_read_reg &&
                                ((id_ex_rd_reg == id_ex_rs1_next) || (id_ex_rd_reg == id_ex_rs2_next)) &&
                                (id_ex_rd_reg != 5'b0));

    assign {pc_write, if_id_write} = ~{2{alu_operand_stall}};
    assign hazard_id_flush = alu_operand_stall;

endmodule
