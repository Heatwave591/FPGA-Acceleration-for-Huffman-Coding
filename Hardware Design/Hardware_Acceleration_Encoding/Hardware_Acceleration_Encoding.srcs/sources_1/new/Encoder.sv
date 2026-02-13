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
    input logic wr_en,           // These three lines will be used to fill up the dictionary
    input logic [7:0] addr_config,     // Huffman = Dynamic; addr_config holds address; data_config holds the corresponding symbol
    input logic [19:0] data_config,     // My dumbass will forget why I defined this if I dont write this comment   
                                        
    // Input
    input  logic [7:0] symbol_in,
    input  logic symbol_valid,
    output logic symbol_ready,

    // Output
    output logic [31:0] stream_out,
    output logic stream_valid,
    input  logic stream_ready
);

logic [19:0] code_table [255:0];        // Defining LUT and writing into it

initial begin
    integer i;
    for (i = 0; i < 256; i = i + 1)
        code_table[i] = 20'd0;
end

always_ff @(posedge clk) begin
    if (wr_en) begin
        code_table[addr_config] <= data_config;
    end
end

    
    
    
    logic [63:0] accumulator;
    
    (* mark_debug = "true" *) logic [5:0] bit_count;
    logic[15:0] current_code;
    logic[3:0] current_len;
    assign {current_len, current_code} = code_table[symbol_in];
    
    
    // This is the control logic. Assining valid if stream is ready or if there is space is available
    // Check workflow picture in the github repo
    
    assign symbol_ready = (bit_count < 32) || stream_ready;
    assign stream_valid = (bit_count >= 32);    // stream is valid if thr no of bits is more than 32
    assign stream_out   = accumulator[31:0];    // needed o/p is last 32 bits of accumulator
    
    
always_ff @(posedge clk) begin
    if (!rst) begin
        accumulator <= 0;
        bit_count   <= 0;
    end else begin

        logic [63:0] next_acc;
        logic [5:0]  next_count;

        next_acc   = accumulator;
        next_count = bit_count;

        // Flush
        if (stream_valid && stream_ready) begin
            next_acc   = next_acc >> 32;
            next_count = next_count - 32;
        end

        // Accumulate
        if (symbol_valid && symbol_ready) begin
            next_acc   = next_acc |
                         ({48'd0,
                          (current_code & ((1 << current_len) - 1))} << next_count);
            next_count = next_count + current_len;
        end

        accumulator <= next_acc;
        bit_count   <= next_count;
    end
end
endmodule