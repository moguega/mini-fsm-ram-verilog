module ram_minima
    #(parameter WIDTH = 8,
      parameter DEPTH = 4,
      parameter DEPTH_LOG = 2)   // log2(4) = 2
(
    input                   clk,
    input                   we,//write enable
    input  [DEPTH_LOG-1:0]  addr_wr,
    input  [DEPTH_LOG-1:0]  addr_rd,
    input  [WIDTH-1:0]      data_wr,
    output [WIDTH-1:0]      data_rd
);

        reg[WIDTH-1:0] ram[0:DEPTH-1];
  
        always @(posedge clk) begin
            if(we == 1) 
            ram[addr_wr] <= data_wr;
        end
        assign data_rd = ram[addr_rd];
    

endmodule
