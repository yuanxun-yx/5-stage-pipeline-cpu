module ram
    #(
      parameter ADDR_WIDTH = 8,
                DATA_WIDTH = 32,
                INIT_FILE = ""
    )
    (
     input wire clk, 
     input wire we,
     input wire [ADDR_WIDTH-1:0] addr,
     input wire [DATA_WIDTH-1:0] din,
     output wire [DATA_WIDTH-1:0] dout
    );

    // signal declaration
    reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];
    reg [ADDR_WIDTH-1:0] addr_reg;

    // body
    always @(posedge clk)
    begin
        if (we)     // write operation
            ram[addr] <= din;
        addr_reg <= addr;
    end
    // read operation (synchronous)
    assign dout = ram[addr_reg];
    // initial data
    generate if(INIT_FILE != "") 
    initial
        $readmemh(INIT_FILE, ram);
    endgenerate

endmodule
