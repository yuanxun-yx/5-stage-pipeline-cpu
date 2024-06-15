// strategy: check 3 times per 10 ms
// reset is used for clock division unit, which
// requires a debounced reset signal, therefore 
// this special debounce module is created with
// a built-in clock division unit
module reset_db
   (
    input wire clk, reset_n,
    output wire reset_db
   );

   // signal declaration
   reg [6:0] clk_counter_reg = 0;
   reg [2:0] delayed;

   // body
   always @(posedge clk) 
   begin
       clk_counter_reg <= clk_counter_reg + 1;
       if (clk_counter_reg[6]) delayed <= {delayed[1:0], ~reset_n};
   end

   assign reset_db = (delayed == 3'b111) ? 1'b1 : 1'b0;

endmodule