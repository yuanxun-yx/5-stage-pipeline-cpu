// symbolic control signals decalration

// pc_source
localparam
    pc_source_pc_plus_4                             = 3'b000,
    pc_source_pc_plus_offset                        = 3'b001,
    pc_source_alu_result                            = 3'b010,
    pc_source_branch_zero                           = 3'b100,
    pc_source_branch_not_zero                       = 3'b101,
    pc_source_unknown                               = 3'bxxx;
           
// data_to_reg
localparam
    data_to_reg_alu_result                          = 2'b00,
    data_to_reg_memory_data                         = 2'b01,
    data_to_reg_upper_imm                           = 2'b10,
    data_to_reg_pc_plus_4                           = 2'b11,
    data_to_reg_unknown                             = 2'bxx;

// alu_source_a
localparam 
    alu_source_a_rs1                                = 1'b0,
    alu_source_a_pc                                 = 1'b1,
    alu_source_a_unknown                            = 1'bx;

// alu_source_b
localparam 
    alu_source_b_rs2                                = 1'b0,
    alu_source_b_imm                                = 1'b1,
    alu_source_b_unknown                            = 1'bx;
           
// alu_operation
// the purpose of this design is to be as close
// to the funct3 & funct7 of RV32 as possible,
// so that we can simply write alu_operation = {funct7[5], funct3}
localparam 
    alu_operation_add                               = 4'b0000,
    alu_operation_sub                               = 4'b1000,
    alu_operation_sll                               = 4'b0001,
    alu_operation_slt                               = 4'b0010,
    alu_operation_sltu                              = 4'b0011,
    alu_operation_xor                               = 4'b0100,
    alu_operation_srl                               = 4'b0101,
    alu_operation_sra                               = 4'b1101,
    alu_operation_or                                = 4'b0110,
    alu_operation_and                               = 4'b0111,
    alu_operation_unknown                           = 4'bxxxx;

// forwarding control
// forward_alu_a
localparam
    forward_alu_a_original                          = 2'b00,
    forward_alu_a_mem                               = 2'b10,
    forward_alu_a_wb                                = 2'b01,
    forward_alu_a_unknown                           = 2'bxx;
    
// forward_alu_b
localparam
    forward_alu_b_original                          = 2'b00,
    forward_alu_b_mem                               = 2'b10,
    forward_alu_b_wb                                = 2'b01,
    forward_alu_b_unknown                           = 2'bxx;