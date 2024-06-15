`include "debug.vh"

// register file with 32 32-bit registers

module reg_file
    (
     input wire clk, reset, 
     input wire reg_write,
     input wire [4:0] read_addr_a, read_addr_b, write_addr,
     input wire [31:0] write_data,
     output wire [31:0] read_data_a, read_data_b
     `ifdef DEBUG_MODE
     // debug
     ,input wire [6:0] debug_addr,
     output wire [31:0] debug_data
     `endif
    );
    
    // signal declaration
    (* mark_debug = "true" *)reg [31:0] registers [1:31];
    integer i;
    
    // body
    // output two register data
    // register x0 is hardwired with all bits equal to 0
    assign read_data_a = (read_addr_a == 1'b0) ? 32'b0 : registers[read_addr_a];   // rs
    assign read_data_b = (read_addr_b == 1'b0) ? 32'b0 : registers[read_addr_b];   // rt
    
    // write value into given register
    always @(posedge clk, posedge reset)
        if (reset)
            for(i = 1; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        else if ((write_addr != 0) && reg_write)
            registers[write_addr] <= write_data;      // rd

    `ifdef DEBUG_MODE
    assign debug_data = (debug_addr == 32'b0) ? 32'b0 : registers[debug_addr];
    `endif
    
endmodule
