`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/17/2026 04:28:54 PM
// Design Name: 
// Module Name: Encoder
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


module huffman_encoder (
    input logic clk,
    input logic rst,        // Active Low Reset (Reset when 0)

    // Defining the lookup table
    input logic        wr_en,           // These three lines will be used to fill up the dictionary
    input logic [7:0]  addr_config,     // Huffman = Dynamic; addr_config holds address; data_config holds the corresponding symbol
    input logic [19:0] data_config,     // My dumbass will forget why I defined this if I dont write this comment   
                                        
    // Input
    input  logic [7:0]  symbol_in,
    input  logic        symbol_valid,
    output logic        symbol_ready,

    // Output
    output logic [31:0] stream_out,
    output logic        stream_valid,
    input  logic        stream_ready
);

logic [19:0] code_table [255:0];        // Defining LUT and writing into it

    always_ff @(posedge clk) begin
        if (wr_en) begin
            code_table[addr_config] <= data_config;
        end
    end
endmodule