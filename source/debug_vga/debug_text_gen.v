// generates the text for debug data
// provides 30 * 4 = 120 debug data, each entry occupies 20 characters

module debug_text_gen
   (
    // clock freq: 100 MHz (4 * VGA clock freq)
    input wire clk, reset,
    // vga sync signals
    input wire video_on,
    input wire [9:0] pixel_x, pixel_y,
    // debug data signals
    input wire [31:0] debug_data,
    input wire [7*8-1:0] debug_label,  // label of debug signal (7 characters)       
    output wire [6:0] debug_addr,      // debug_addr[6:3]: bit_y, debug_addr[2:0]: col_addr
    // output rgb
    output wire [3:0] red, green, blue
   );

   // signal declaration
   // clock divider
   reg [1:0] clk_counter;
   // data are registered to avoid glitches
   reg [31:0] debug_data_reg, debug_data_next;
   reg [8*8-1:0] debug_label_reg, debug_label_next;
   // register output rgb
   reg [3:0] red_reg, green_reg, blue_reg;
   reg [3:0] red_next, green_next, blue_next;
   // tile coordinate
   wire [6:0] tile_x;
   wire [4:0] tile_y;
   // debug coordinate
   wire [1:0] debug_x;
   wire [4:0] debug_y;
   // char num in one debug entry
   wire [4:0] char_addr;
   // font ROM
   wire [3:0] bit_y;
   wire [2:0] bit_x;
   wire [10:0] rom_addr;
   wire [7:0] font_word;
   wire font_bit;
   // select charactor
   reg [3:0] hex;
   // charactor ASCII code
   reg [6:0] char_ascii;

   // body
   
   // clock counter
   // 4 cycles in this module corespond to 4 cycles in VGA sync
   // module, so this module needs to know which cycle it's in 
   always @(posedge clk, posedge reset)
      if (reset)
         clk_counter <= -2'h1;
      else
         clk_counter <= clk_counter + 2'h1;

   // tile: 16 * 8
   // tile coordinate: pixel_x[9:3], pixel_y[8:4]
   assign tile_x = pixel_x[9:3];
   assign tile_y = pixel_y[8:4];

   // debug: 30 * 4
   assign debug_x = tile_x / 20;
   assign debug_y = tile_y;

   // output the number of output debug signal in the next cycle
   assign debug_addr = {debug_y, debug_x};

   // char num in one debug entry
   assign char_addr = tile_x % 20;

   // register two input data
   always @(posedge clk, posedge reset)
      if (reset)
         begin
            debug_data_reg <= 32'b0;
            debug_label_reg <= 64'b0;
         end
      else 
         begin
            debug_data_reg <= debug_data_next;
            debug_label_reg <= debug_label_next;
         end

   always @* 
      begin
         debug_data_next = debug_data_reg;
         debug_label_next = debug_label_reg;
         if (video_on && (char_addr == 0) && (clk_counter == 2'h0))
            begin
               debug_data_next = debug_data;
               debug_label_next = debug_label;
            end
      end

   // get ASCII code of character
   always @*
      begin
         hex = 4'h0;
         char_ascii = 7'b0;
         // label
         if (char_addr >= 2 && char_addr <= 8)
            case (char_addr)
               2: char_ascii = debug_label_reg[8*7-1:8*6];
               3: char_ascii = debug_label_reg[8*6-1:8*5];
               4: char_ascii = debug_label_reg[8*5-1:8*4];
               5: char_ascii = debug_label_reg[8*4-1:8*3];
               6: char_ascii = debug_label_reg[8*3-1:8*2];
               7: char_ascii = debug_label_reg[8*2-1:8*1];
               8: char_ascii = debug_label_reg[8*1-1:8*0];
            endcase
         // data
         else if (char_addr >= 10 && char_addr <= 17)
            begin
               case (char_addr)
                  10: hex = debug_data_reg[4*8-1:4*7];
                  11: hex = debug_data_reg[4*7-1:4*6];
                  12: hex = debug_data_reg[4*6-1:4*5];
                  13: hex = debug_data_reg[4*5-1:4*4];
                  14: hex = debug_data_reg[4*4-1:4*3];
                  15: hex = debug_data_reg[4*3-1:4*2];
                  16: hex = debug_data_reg[4*2-1:4*1];
                  17: hex = debug_data_reg[4*1-1:4*0];
               endcase
               if (hex < 10)
                  char_ascii = hex + "0";
               else
                  char_ascii = hex - 10 + "A";
            end
      end
   
   // bit row address & font ROM address
   assign bit_y = pixel_y[3:0];
   assign rom_addr = {char_ascii, bit_y};
   // bit col address
   // use delayed coordinate to select a bit
   assign bit_x = pixel_x[2:0];
   assign font_bit = font_word[~bit_x];      // data in ROM is stored in reverse order

   // instantiate font ROM
   font_rom font_unit
      (.clk(clk), .addr(rom_addr), .data(font_word));

   // rgb signals
   always @(posedge clk, posedge reset)
      if (reset)
         begin
            red_reg <= 4'h0;
            green_reg <= 4'h0;
            blue_reg <= 4'h0;
         end
      else
         begin
            red_reg <= red_next;
            green_reg <= green_next;
            blue_reg <= blue_next;
         end
         
   always @*
      begin
         red_next = red_reg;
         green_next = green_reg;
         blue_next = blue_reg;
         if (clk_counter == 2'd3)
            begin
               red_next = font_bit? 4'hf: 4'h0;
               green_next = font_bit? 4'hf: 4'h0;
               blue_next = font_bit? 4'hf: 4'h0;
            end
      end

   assign red = red_reg;
   assign green = green_reg;
   assign blue = blue_reg;


endmodule

