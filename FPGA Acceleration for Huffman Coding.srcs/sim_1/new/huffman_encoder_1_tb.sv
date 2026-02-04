`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2026 03:14:53 PM
// Design Name: 
// Module Name: huffman_encoder_1_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module huffman_encoder_tb;

    logic clk;
    logic rst;

    logic        wr_en;
    logic [7:0]  addr_config;
    logic [19:0] data_config;

    logic [7:0]  symbol_in;
    logic        symbol_valid;
    logic        symbol_ready;

    logic [31:0] stream_out;
    logic        stream_valid;
    logic        stream_ready;

    // DUT
    huffman_encoder dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .addr_config(addr_config),
        .data_config(data_config),
        .symbol_in(symbol_in),
        .symbol_valid(symbol_valid),
        .symbol_ready(symbol_ready),
        .stream_out(stream_out),
        .stream_valid(stream_valid),
        .stream_ready(stream_ready)
    );

    // Clock
    always #5 clk = ~clk;

    // Tasks
    task write_code(input [7:0] sym, input [3:0] len, input [15:0] code);
        begin
            @(posedge clk);
            wr_en        = 1;
            addr_config = sym;
            data_config = {len, code};
            @(posedge clk);
            wr_en        = 0;
        end
    endtask

    task send_symbol(input [7:0] sym);
        begin
            wait(symbol_ready);
            @(posedge clk);
            symbol_in    = sym;
            symbol_valid = 1;
            @(posedge clk);
            symbol_valid = 0;
        end
    endtask

    // Test sequence
    initial begin
        clk = 0;
        rst = 0;
        wr_en = 0;
        symbol_valid = 0;
        stream_ready = 1;

        // Reset
        #20 rst = 1;

        // Dictionary
        // A = 101 (3 bits)
        // B = 01  (2 bits)
        write_code(8'd65, 4'd3, 16'b101);
        write_code(8'd66, 4'd2, 16'b01);

        // Send data: A B A B A B ...
        repeat (20) begin
            send_symbol(8'd65);
            send_symbol(8'd66);
        end

        #100 $finish;
    end

endmodule
