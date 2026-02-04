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
// Description: Huffman Encoder with variable-length bit packing
// 
// Dependencies: 
// 
// Revision:
// Revision 1.00 - Fixed multiple drivers, reset, and handshake logic
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

    always_ff @(posedge clk)
    begin
    if (wr_en) begin
        code_table[addr_config] <= data_config;
    end
        
    if (!rst)
    begin
        bit_count <= 6'd0;
    end

    end
    
    
    
    logic [63:0] accumulator;
    
    (* mark_debug = "true" *) logic [5:0] bit_count;
    logic[15:0] current_code;
    logic[3:0] current_len;
    assign {current_len, current_code} = code_table[symbol_in];
    
    
    // This is the control logic. Assining valid if stream is ready or if there is space is available
    assign symbol_ready = (bit_count < 32) || stream_ready;
    assign stream_valid = (bit_count >= 32);    // stream is valid if thr no of bits is more than 32
    assign stream_out   = accumulator[31:0];    // needed o/p is last 32 bits of accumulator
    
    
    always_ff @(posedge clk) begin
        if (!rst) begin                         // Note that I have used actuiive low reset
            accumulator <= 64'd0;
            bit_count   <= 6'd0;
        end 
        
        else begin
            if(stream_valid && stream_ready)
            begin
                if(stream_valid && symbol_ready)
                begin
                    accumulator <= (accumulator >> 32)|(64'(current_code) << (bit_count - 32));
                    bit_count   <= (bit_count - 32) + current_len;
                end 
               else begin
                    accumulator <= accumulator >> 32;
                    bit_count <= bit_count - 32;
               end
            end
            
       else if (symbol_valid && symbol_ready)
       begin
            accumulator <= accumulator|(64'(current_code) << bit_count);
            bit_count   <= bit_count + current_len;
       end
       end
       end
endmodule