`timescale 1ns / 1ps
`include "debug.vh"

module soc
    (
     input wire clk_200m_p, clk_200m_n,
     input wire reset_n,
     output wire [3:0] red, green, blue,
     output wire v_sync, h_sync
    );

    // signal declaration
    // 200 MHz clock derived from two differential signals
    wire clk_200m;
    // debounced reset signal (active high)
    wire reset_db;
    // clock division counter
    wire [31:0] clk_div_counter;
    `ifdef DEBUG_MODE
    // VGA
    wire video_on;
    wire [9:0] pixel_x, pixel_y;
    wire [6:0] debug_addr;
    wire [31:0] debug_data, reg_debug_data;
    wire [55:0] debug_label;
    `endif

    // differential input buffer
    IBUFGDS
       #(
         .DIFF_TERM("FALSE"),       // differential termination
         .IBUF_LOW_PWR("TRUE"),     // low power
         .IOSTANDARD("DEFAULT")     // I/O standard of this buffer
        )
    ibufgds_unit
        (
         .I(clk_200m_p),
         .IB(clk_200m_n),
         .O(clk_200m)
        );

    // debounce reset signal (active low)
    reset_db reset_db_unit
        (
         .clk(clk),
         .reset_n(reset_n),
         .reset_db(reset_db)
        );

    // clock division unit
    clk_div clk_div_unit
        (
         .clk(clk_200m),
         .reset(reset_db),
         .clk_div_counter(clk_div_counter)
        );
        
    // RISC-V single-cycle CPU
    // Harvard Architecture
    cpu cpu_unit 
        (
         .clk(clk_200m),
         .reset(reset_db)
         `ifdef DEBUG_MODE
         // debug
         ,.debug_addr(debug_addr),
         .debug_data(reg_debug_data)
         `endif
        );
        
    `ifdef DEBUG_MODE
    
    // VGA part

    debug_signal_selection data_selection_unit
        (
         .reg_file(reg_debug_data),
         .pc(pc),
         
         .debug_addr(debug_addr),
         .debug_data(debug_data),
         .debug_label(debug_label)
        );

    debug_text_gen text_gen_unit
        (
         .clk(clk_div_counter[0]), .reset(reset_db),
         .video_on(video_on),
         .debug_data(debug_data), .debug_label(debug_label), .debug_addr(debug_addr),
         .pixel_x(pixel_x), .pixel_y(pixel_y),
         .red(red), .green(green), .blue(blue)
        );

    vga_sync vga_sync_unit
        (
         .clk(clk_div_counter[2]), .reset(reset_db),
         .video_on(video_on),
         .pixel_x(pixel_x), .pixel_y(pixel_y),
         .h_sync(h_sync), .v_sync(v_sync)
        );
    `endif

endmodule
