module debug_signal_selection
    (
     input wire [31:0] reg_file,
     input wire [31:0] pc,
     
     input wire [6:0] debug_addr,
     output reg [31:0] debug_data,
     output reg [7*8-1:0] debug_label
    );

    always @*
        begin
            debug_data = 32'b0;
            debug_label = 56'b0;
            case (debug_addr)
                7'h00: begin debug_data = pc; debug_label = "pc"; end
                7'h01: begin debug_data = reg_file; debug_label = "ra"; end
                7'h02: begin debug_data = reg_file; debug_label = "sp"; end
                7'h03: begin debug_data = reg_file; debug_label = "gp"; end
                7'h04: begin debug_data = reg_file; debug_label = "tp"; end
                7'h05: begin debug_data = reg_file; debug_label = "t0"; end
                7'h06: begin debug_data = reg_file; debug_label = "t1"; end
                7'h07: begin debug_data = reg_file; debug_label = "t2"; end
                7'h08: begin debug_data = reg_file; debug_label = "s0"; end
                7'h09: begin debug_data = reg_file; debug_label = "s1"; end
                7'h0a: begin debug_data = reg_file; debug_label = "a0"; end
                7'h0b: begin debug_data = reg_file; debug_label = "a1"; end
                7'h0c: begin debug_data = reg_file; debug_label = "a2"; end
                7'h0d: begin debug_data = reg_file; debug_label = "a3"; end
                7'h0e: begin debug_data = reg_file; debug_label = "a4"; end
                7'h0f: begin debug_data = reg_file; debug_label = "a5"; end
                7'h10: begin debug_data = reg_file; debug_label = "a6"; end
                7'h11: begin debug_data = reg_file; debug_label = "a7"; end
                7'h12: begin debug_data = reg_file; debug_label = "s2"; end
                7'h13: begin debug_data = reg_file; debug_label = "s3"; end
                7'h14: begin debug_data = reg_file; debug_label = "s4"; end
                7'h15: begin debug_data = reg_file; debug_label = "s5"; end
                7'h16: begin debug_data = reg_file; debug_label = "s6"; end
                7'h17: begin debug_data = reg_file; debug_label = "s7"; end
                7'h18: begin debug_data = reg_file; debug_label = "s8"; end
                7'h19: begin debug_data = reg_file; debug_label = "s9"; end
                7'h1a: begin debug_data = reg_file; debug_label = "s10"; end
                7'h1b: begin debug_data = reg_file; debug_label = "s11"; end
                7'h1c: begin debug_data = reg_file; debug_label = "t3"; end
                7'h1d: begin debug_data = reg_file; debug_label = "t4"; end
                7'h1e: begin debug_data = reg_file; debug_label = "t5"; end
                7'h1f: begin debug_data = reg_file; debug_label = "t6"; end
            endcase
        end

endmodule
