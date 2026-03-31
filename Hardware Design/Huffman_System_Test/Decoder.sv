`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2026 02:22:06 PM
// Design Name: 
// Module Name: Decoder
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

module Decoder (
    input  logic clk,
    input  logic rst,   // active low reset

    // ----------------------------
    // Configuration Interface
    // ----------------------------

    input  logic        wr_en,
    input  logic [1:0]  table_sel,
    input  logic [7:0]  addr_config,
    input  logic [15:0] data_config,

    // ----------------------------
    // Compressed stream input
    // ----------------------------

    input  logic [31:0] stream_in,
    input  logic        stream_valid,
    output logic        stream_ready,

    // ----------------------------
    // Decoded output
    // ----------------------------

    output logic [7:0]  symbol_out,
    output logic        symbol_valid,
    input  logic        symbol_ready
);

    // ------------------------------------------------
    // Bit Window
    // ------------------------------------------------

    logic [63:0] bit_window;
    logic [6:0]  bit_count;

    // ------------------------------------------------
    // Canonical Huffman Tables
    // ------------------------------------------------

    logic [15:0] first_code [1:16];
    logic [15:0] base       [1:16];
    logic [7:0]  symbol_table [0:255];

    // ------------------------------------------------
    // Configuration Writes
    // ------------------------------------------------

    always_ff @(posedge clk) begin
        if(wr_en) begin

            case(table_sel)

                2'd0:
                    first_code[addr_config] <= data_config;

                2'd1:
                    base[addr_config] <= data_config;

                2'd2:
                    symbol_table[addr_config] <= data_config[7:0];

            endcase

        end
    end

    // ------------------------------------------------
    // Peek Logic
    // ------------------------------------------------

    logic [15:0] peek;
    assign peek = bit_window[63:48];    // MSB-first: read from top of window

    // ------------------------------------------------
    // Length Detection
    // ------------------------------------------------

    logic [4:0] length;
    integer i;

    always_comb begin
        length = 1;

        for(i=1;i<=16;i=i+1) begin
            if(peek >= first_code[i])
                length = i;
        end
    end

    // ------------------------------------------------
    // Symbol Index
    // ------------------------------------------------

    logic [15:0] index;

    assign index = base[length] + ((peek - first_code[length]) >> (16 - length));

    assign symbol_out = symbol_table[index];

    // ------------------------------------------------
    // Handshake
    // ------------------------------------------------

    assign symbol_valid = (bit_count >= 1);
    assign stream_ready = (bit_count <= 32);

    // ------------------------------------------------
    // Main Decoder Logic
    // ------------------------------------------------

    logic [63:0] next_window;
    logic [6:0]  next_count;

    always_comb begin
        next_window = bit_window;
        next_count  = bit_count;

        // Load bits: place MSB-aligned so peek sees them at [63:48]
        if(stream_valid && stream_ready) begin
            next_window = next_window | (64'(stream_in) << (32 - next_count));
            next_count  = next_count + 32;
        end

        // Output symbol: consume from MSB side
        if(symbol_valid && symbol_ready) begin
            next_window = next_window << length;
            next_count  = next_count - length;
        end
    end

    always_ff @(posedge clk) begin

        if(!rst) begin
            bit_window <= 0;
            bit_count  <= 0;
        end

        else begin
            bit_window <= next_window;
            bit_count  <= next_count;
        end

    end

endmodule