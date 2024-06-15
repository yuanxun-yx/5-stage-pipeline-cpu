// arithmetic & logical unit

module alu
    (
     input wire [31:0] a, b,
     input wire [3:0] alu_operation,
     output reg [31:0] result
    );
    
    // symbolic operation code declaration
    `include "symbolic_control_signals.vh"
    
    // body
    // calculate result for ALU
    always @*
        case (alu_operation)
            alu_operation_and: result = a & b;
            alu_operation_or:  result = a | b;
            alu_operation_add: result = a + b; 
            alu_operation_xor: result = a ^ b;
            alu_operation_sub: result = a - b;
            alu_operation_slt: result = $signed(a) < $signed(b);
            alu_operation_sltu: result = a < b;
            // only the lower 5 bits of register rs2 are considered
            // for the shift amount
            alu_operation_sll: result = a << b[4:0];
            alu_operation_srl: result = a >> b[4:0];
            alu_operation_sra: result = $signed(a) >>> b[4:0];
            default: result = 32'hxxxx_xxxx;
        endcase

endmodule
