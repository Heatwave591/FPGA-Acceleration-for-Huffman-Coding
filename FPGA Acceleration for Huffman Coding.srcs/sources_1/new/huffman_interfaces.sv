`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/17/2026 04:29:44 PM
// Design Name: 
// Module Name: huffman_interfaces
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


interface huffman_stream_if (input logic clk);
    logic [31:0] data;
    logic valid;
    logic ready;

    modport source (output data, valid, input ready);
    modport sink   (input data, valid, output ready);
endinterface