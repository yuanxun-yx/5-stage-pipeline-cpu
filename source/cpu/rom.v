module rom
    #(
      parameter ADDR_WIDTH = 8,
                DATA_WIDTH = 32,
                INIT_FILE = ""
    )
    (
     input wire clk, 
     input wire [ADDR_WIDTH-1:0] addr,
     output wire [DATA_WIDTH-1:0] data
    );

    // signal declaration
    reg [DATA_WIDTH-1:0] rom [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH-1:0] addr_reg;

    // body
    always @(posedge clk)
        addr_reg <= addr;
    // read operation (synchronous)
    assign data = rom[addr_reg];
    // initial data
    generate if(INIT_FILE != "") 
    initial
        $readmemh(INIT_FILE, rom);
    endgenerate

endmodule
