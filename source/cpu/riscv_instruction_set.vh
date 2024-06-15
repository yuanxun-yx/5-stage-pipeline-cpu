// symbolic opcode and funct3 of RISC-V ISA
// reference: The RISC-V Instruction Set Manual (Document Version 20191214-draft)

// opcode (7)
localparam
    opcode_load             = 7'b00_000_11,
    opcode_load_fp          = 7'b00_001_11,
    opcode_custom_0         = 7'b00_010_11,
    opcode_misc_mem         = 7'b00_011_11,
    opcode_op_imm           = 7'b00_100_11,
    opcode_auipc            = 7'b00_101_11,
    opcode_op_imm_32        = 7'b00_110_11,
    
    opcode_store            = 7'b01_000_11,
    opcode_store_fp         = 7'b01_001_11,
    opcode_custom_1         = 7'b01_010_11,
    opcode_amo              = 7'b01_011_11,
    opcode_op               = 7'b01_100_11,
    opcode_lui              = 7'b01_101_11,
    opcode_op_32            = 7'b01_110_11,
    
    opcode_madd             = 7'b10_000_11,
    opcode_msub             = 7'b10_001_11,
    opcode_nmsub            = 7'b10_010_11,
    opcode_nmadd            = 7'b10_011_11,
    opcode_op_fp            = 7'b10_100_11,
    // reserved             = 7'b10_101_11,
    opcode_custom_2_rv128   = 7'b10_110_11,
    
    opcode_branch           = 7'b11_000_11,
    opcode_jalr             = 7'b11_001_11,
    // reserved             = 7'b11_010_11,
    opcode_jal              = 7'b11_011_11,
    opcode_system           = 7'b11_100_11,
    // reserved             = 7'b11_101_11,
    opcode_custom_3_rv128   = 7'b11_110_11;

// funct3 (3) for RV32I
localparam
    // R-type & I-type (calculation)
    funct3_add_sub          = 3'b000,   // addi
    funct3_sll              = 3'b001,   // slli
    funct3_slt              = 3'b010,   // slti
    funct3_sltu             = 3'b011,   // sltiu
    funct3_xor              = 3'b100,   // xori
    funct3_srl_sra          = 3'b101,   // srli/srai
    funct3_or               = 3'b110,   // ori
    funct3_and              = 3'b111,   // andi
    // B-type
    funct3_beq              = 3'b000,
    funct3_bne              = 3'b001,
    funct3_blt              = 3'b100,
    funct3_bge              = 3'b101,
    funct3_bltu             = 3'b110,
    funct3_bgeu             = 3'b111,

    // I-type (load)
    funct3_lb               = 3'b000,
    funct3_lh               = 3'b001,
    funct3_lw               = 3'b010,
    funct3_lbu              = 3'b100,
    funct3_lhu              = 3'b101,
    
    // S-type
    funct3_sb               = 3'b000,
    funct3_sh               = 3'b001,
    funct3_sw               = 3'b010;

// funct7 (7) for RV32I
localparam
    // R-type (add/sub, srl/sra) & I-type (srli/srai)
    funct7_0                = 7'b0000000,
    funct7_1                = 7'b0100000;

localparam
    nop                     = 32'h0000_0013;