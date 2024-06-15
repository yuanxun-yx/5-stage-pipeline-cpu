module clk_div
    (
     input wire clk,
     input wire reset,
     output wire [31:0] clk_div_counter
    );
    
    // signal declaration
    reg [31:0] clk_div_counter_reg;
    
    // body
    assign clk_div_counter = clk_div_counter_reg;
    
    always @(posedge clk or posedge reset)
        if (reset)
            clk_div_counter_reg <= 32'b0;
        else
            clk_div_counter_reg <= clk_div_counter_reg + 32'b1;
    
endmodule
