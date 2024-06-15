module vga_sync
    (
     input wire clk,                      // VGA clock (25 MHz)
     input wire reset,                    // the screen is reset after 'reset' is released
    
     output wire video_on,                // indicates whether current pixel is in display area
     output wire [9:0] pixel_x, pixel_y,  // x, y coordinates of current pixel
     output wire h_sync, v_sync           // horizontal and vertical sync 
    );
    
    // note:
    // VGA screen on SWORD scans from left-bottom corner of the
    // screen, which means the vertical scan is in reverse order,
    // which the horizontal scan is in regular order. 
    // to avoid subtration in the output circuit of pixel_x and pixel_y,
    // display area region will always be the first in both vertical and 
    // horizontal directions, which means:
    // order of four regions:
    // hotizontal: retrace, front border, display area, back border
    // vertical: retrace, back border, display area, front border
    
    // constant declaration
    // VGA 640-by-480 sync parameters
    localparam HD = 640;    // horizontal display area
    localparam HF = 48;     // horizontal front (left) border
    localparam HB = 16;     // horizontal back (right) border
    localparam HR = 96;     // horizontal retrace
    localparam VD = 480;    // vertical display area
    localparam VF = 10;     // vertical front (top) border
    localparam VB = 33;     // vertical back (bottom) border
    localparam VR = 2;      // vertical retrace
    
    // sync counters
    reg [9:0] h_count_reg, h_count_next;
    reg [9:0] v_count_reg, v_count_next;
    // output buffer
    reg h_sync_reg, v_sync_reg;
    wire h_sync_next, v_sync_next;
    // end condition
    wire h_end, v_end;
    
    // registers
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            h_count_reg <= 10'b0;
            v_count_reg <= 10'b0;
            h_sync_reg <= 1'b0;
            v_sync_reg <= 1'b0;
        end
        else begin
            h_count_reg <= h_count_next;
            v_count_reg <= v_count_next;
            h_sync_reg <= h_sync_next;
            v_sync_reg <= v_sync_next;
        end
    end
    
    // end condition
    assign h_end = (h_count_reg == (HD + HF + HB + HR - 1));
    assign v_end = (v_count_reg == (VD + VF + VB + VR - 1));
    
    // next-state logic of mod-800 horizontal sync counter
    always @* begin
        // horizontal counter reaches 799
        if (h_end)
            h_count_next = 10'b0;
        // counter++
        else
            h_count_next = h_count_reg + 1;
    end
    
    // next-state logic of mod-525 vertical sync counter
    always @* begin
        // horizontal counter reaches 524
        if (h_end)
            begin
                if (v_end)
                    v_count_next = 10'b0;
                else
                    v_count_next = v_count_reg + 1;
            end
        else
            v_count_next = v_count_reg;
    end
    
    // buffered to avoid glitches
    // rgb output SHOULD also be buffered to compensate for the delay
    // sync is asserted during front border, display area and back border
    // in other words, it's deasserted during retrace
    assign h_sync_next = (h_count_reg >= HR);//(h_count_reg < (HD + HB)) || (h_count_reg >= (HD + HB + HR));
    assign v_sync_next = (v_count_reg >= VR);//(v_count_reg < (VD + VF)) || (v_count_reg >= (VD + VF + VR));
    
    // video on/off (inside display area)
    assign video_on = (h_count_reg >= (HR + HF)) && (h_count_reg < (HR + HF + HD)) && 
                      (v_count_reg >= (VR + VB)) && (v_count_reg < (VR + VB + VD));//(h_count_reg < HD) && (v_count_reg < VD);
    
    // output 
    // sync signals
    assign h_sync = h_sync_reg;
    assign v_sync = v_sync_reg;
    // x and y cooridinates
    assign pixel_x = h_count_reg - (HR + HF);
    assign pixel_y = v_count_reg - (VR + VB);
    
endmodule
