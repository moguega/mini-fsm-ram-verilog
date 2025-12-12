`timescale 1ns/1ps
module tb_top_minimo();
reg rst_n,start;
reg clk = 0;
reg ram_in_we;
wire ram_out_we;
wire  [0:0] ram_out_addr_wr;
wire [15:0] ram_out_data_wr;

reg [1:0] addr_wr;
reg [7:0] data_wr;
reg [7:0] data_read;
integer i;

wire done;

mini_top_fsm dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .ram_in_we(ram_in_we),
    .ram_in_addr_wr(addr_wr),
    .ram_in_data_wr(data_wr),
    .ram_out_we(ram_out_we),          
    .ram_out_addr_wr(ram_out_addr_wr),
    .ram_out_data_wr(ram_out_data_wr),
    .done(done)
);


initial forever begin
    #1 clk = ~clk;    
end

task write_data (input [1:0] addres_data, input [7:0] data); begin
    @(posedge clk)
    ram_in_we = 1;
    data_wr = data;
    addr_wr = addres_data;
    $display("dado escrito: %b, endereço: %b",data_wr,addr_wr);
    @(posedge clk)
    ram_in_we = 0;
end
endtask
    initial begin
        rst_n = 0; start = 0;
        #2.5;
        rst_n = 1; 
        for (i = 0; i < 4; i = i + 1) begin
            write_data(i[1:0], $random);
        end
           
         @(posedge clk);
             start = 1;
         @(posedge clk);
             start = 0;

        wait (done);
        
        #40 $stop;
    end
    always @(posedge clk) begin
            if (ram_out_we)
            $display("RAM_OUT[%0d] = 0x%04h", ram_out_addr_wr, ram_out_data_wr);
end


endmodule