module mini_top_fsm (
    input        clk,
    input        rst_n,
    input        start,          // pulso para iniciar
    // interface RAM_IN (4x8)
    input          ram_in_we,
    input [1:0]   ram_in_addr_wr,
    input [7:0]   ram_in_data_wr,
    output reg [1:0]   ram_in_addr_rd,
    input      [7:0]   ram_in_data_rd,
    // interface RAM_OUT (2x16)
    output reg         ram_out_we,
    output reg [0:0]   ram_out_addr_wr, // só 0 ou 1
    output reg [15:0]  ram_out_data_wr,
    // status
    output reg         done
);

    //definido com one-hot code
        parameter [6:0] IDLE = 7'b0000001 ,
                        READ0 = 7'b0000010 ,
                        READ1 = 7'b0000100,
                        WRITE0 = 7'b0001000 ,
                        READ2 = 7'b0010000 ,
                        READ3 = 7'b0100000 ,
                        WRITE1 = 7'b1000000;

        reg[6:0] state,next_state;
        reg[7:0] byte0_buf, byte1_buf;
        wire [0:0] ram_out_addr_rd_dummy = 1'b0;
        wire [15:0] ram_out_dado_lido;

    ram_minima #(.WIDTH(8),.DEPTH(4), .DEPTH_LOG(2))
    RAM_IN(
            .clk(clk),
            .we(ram_in_we),
            .addr_wr(ram_in_addr_wr),
            .addr_rd(ram_in_addr_rd),
            .data_wr(ram_in_data_wr),
            .data_rd(ram_in_data_rd)
    );

        ram_minima #(.WIDTH(16),.DEPTH(2), .DEPTH_LOG(1))
    RAM_out(
            .clk(clk),
            .we(ram_out_we),
            .addr_wr(ram_out_addr_wr),
            .addr_rd(ram_out_addr_rd_dummy),
            .data_wr(ram_out_data_wr),
            .data_rd(ram_out_dado_lido)
    );
       always @(*) begin
        next_state        = state;       
        ram_in_addr_rd    = 0;
        ram_out_we        = 0;
        ram_out_addr_wr   = 0;
        ram_out_data_wr   = 16'd0;
        done              = 0;
       
        case (state)
            IDLE : begin
                if(start)
                next_state = READ0;
                else next_state = IDLE;
            end 
            READ0 : begin
                ram_in_addr_rd = 2'd0;
                next_state = READ1;
            end
             READ1 : begin
                ram_in_addr_rd = 2'd1;
                next_state = WRITE0;
            end
            WRITE0 : begin
                ram_out_we = 1;
                ram_out_addr_wr = 1'd0;
                ram_out_data_wr = {byte1_buf,byte0_buf};
                next_state = READ2;
            end
            READ2 : begin
                ram_in_addr_rd = 2'd2;
                next_state = READ3;
            end
            READ3 : begin
                ram_in_addr_rd = 2'd3;
                next_state = WRITE1;
            end
            WRITE1 : begin
                 ram_out_we = 1;
                ram_out_addr_wr = 1'd1;
                ram_out_data_wr = {byte1_buf,byte0_buf};
                done = 1;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
        end
    // 5) Bloco sequencial de estado: always @(posedge clk or negedge rst_n)
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n)begin
                    state <= IDLE;
                end else begin
                    state <= next_state;
                end
            end
    // 6) Bloco sequencial para buffers de bytes (quando ler de RAM_IN, guardar em byte0_buf/byte1_buf)
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    byte0_buf <=0;
                    byte1_buf <=0;
                end
                else begin
                case (state)
                    READ0, READ2: byte0_buf <= ram_in_data_rd;
                    READ1, READ3: byte1_buf <= ram_in_data_rd;
                endcase
                end
            end
endmodule
