`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2026 03:14:14 PM
// Design Name: 
// Module Name: huffman_encoder_1
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

module huffman_encoder (
    input  logic        clk,
    input  logic        rst,          // active LOW

    // Configuration interface (dictionary write)
    input  logic        wr_en,
    input  logic [7:0]  addr_config,  // symbol index
    input  logic [19:0] data_config,  // {len[3:0], code[15:0]}

    // Input stream
    input  logic [7:0]  symbol_in,
    input  logic        symbol_valid,
    output logic        symbol_ready,

    // Output stream
    output logic [31:0] stream_out,
    output logic        stream_valid,
    input  logic        stream_ready
);

    // ---------------- Dictionary ----------------
    logic [19:0] code_table [0:255];

    always_ff @(posedge clk) begin
        if (wr_en) begin
            code_table[addr_config] <= data_config;
        end
    end

    // ---------------- Core state ----------------
    logic [63:0] accumulator;
    logic [5:0]  bit_count;

    logic [3:0]  current_len;
    logic [15:0] current_code;

    assign {current_len, current_code} = code_table[symbol_in];

    // ---------------- Handshake logic ----------------
    assign symbol_ready = (bit_count < 32) || stream_ready;
    assign stream_valid = (bit_count >= 32);
    assign stream_out   = accumulator[31:0];

    // ---------------- Main datapath ----------------
    always_ff @(posedge clk) begin
        if (!rst) begin
            accumulator <= 64'd0;
            bit_count   <= 6'd0;
        end else begin

            // FLUSH
            if (stream_valid && stream_ready) begin
                accumulator <= accumulator >> 32;
                bit_count   <= bit_count - 32;
            end

            // ACCUMULATE
            if (symbol_valid && symbol_ready) begin
                accumulator <= accumulator
                             | ( (current_code & ((1 << current_len) - 1))
                                 << bit_count );
                bit_count   <= bit_count + current_len;
            end
        end
    end

endmodule
