`timescale 1ns / 1ps

module cpu_sim
    #(parameter T=10)
    ();
    
    // signal declaration
    reg clk, mem_clk;
    reg reset;
    
    // instatiate the circuit under test
    cpu uut (
       .clk(clk),
       .reset(reset)
    );
    
    // clock
    always 
    begin
        clk = 1; #(T/2);
        clk = 0; #(T/2);
    end
    
    initial 
    begin
        reset = 1;
        #(T);
        
        reset = 0;
        
    end
    
endmodule
