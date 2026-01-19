`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/19/2026 03:41:36 PM
// Design Name: 
// Module Name: huffman_encoder_tb
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

    // ------------------------------------------------
    // 1. Signal Declaration
    // ------------------------------------------------
    logic clk;
    logic rst; // Active Low

    // Config Interface
    logic        wr_en;
    logic [7:0]  addr_config;
    logic [19:0] data_config;

    // Input Stream
    logic [7:0]  symbol_in;
    logic        symbol_valid;
    logic        symbol_ready; // Output from DUT

    // Output Stream
    logic [31:0] stream_out; // Output from DUT
    logic        stream_valid; // Output from DUT
    logic        stream_ready;

    // ------------------------------------------------
    // 2. Instantiate the DUT (Device Under Test)
    // ------------------------------------------------
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

    // ------------------------------------------------
    // 3. Clock Generation (100MHz)
    // ------------------------------------------------
    always #5 clk = ~clk; // Toggle every 5ns

    // ------------------------------------------------
    // 4. Test Procedures
    // ------------------------------------------------
    initial begin
        // --- Initialize Signals ---
        clk = 0;
        rst = 0; // Hold in Reset (Active Low)
        wr_en = 0;
        addr_config = 0;
        data_config = 0;
        symbol_in = 0;
        symbol_valid = 0;
        stream_ready = 1; // Downstream is ready by default

        // --- Apply Reset ---
        #20;
        rst = 1; // Release Reset
        #10;

        // --- PHASE 1: Configuration ---
        $display("--- Starting Configuration ---");
        
        // Let's define a simple codebook:
        // 'A' (0x41) -> Len: 2, Code: 11 (binary) -> 0x20003
        // 'B' (0x42) -> Len: 4, Code: 0101        -> 0x40005
        // 'C' (0x43) -> Len: 30, Code: All 1s     -> 0x1E_3FFFFFFF (Big code to force flush)

        configure_symbol(8'h41, 4'd2,  16'b11);   // A = 11
        configure_symbol(8'h42, 4'd4,  16'b0101); // B = 0101
        configure_symbol(8'h43, 4'd15, 16'hFFFF); // C = 15 ones (Length 15)

        #20;
        $display("--- Configuration Done ---");

        // --- PHASE 2: Streaming Data ---
        // We will send enough data to fill the 32-bit buffer and force an output.
        
        // Send 'A' (2 bits). Accumulator: 2 bits.
        send_symbol(8'h41); 
        
        // Send 'B' (4 bits). Accumulator: 6 bits.
        send_symbol(8'h42);
        
        // Send 'C' (15 bits). Accumulator: 21 bits.
        send_symbol(8'h43);

        // Send 'C' again (15 bits). Accumulator: 36 bits. 
        // This should trigger a FLUSH of 32 bits, leaving 4 bits in buffer.
        send_symbol(8'h43);

        // --- PHASE 3: Backpressure Test ---
        $display("--- Testing Backpressure ---");
        stream_ready = 0; // Downstream is BUSY!
        
        // Send 'A' (2 bits). Accumulator: 6 bits.
        send_symbol(8'h41);
        
        // Keep sending 'C' until buffer fills up.
        // Since stream_ready=0, the DUT should eventually drop 'symbol_ready' to 0.
        repeat(5) send_symbol(8'h43);

        #50;
        stream_ready = 1; // Unblock downstream
        #100;

        $display("--- Test Completed ---");
        $finish;
    end

    // ------------------------------------------------
    // Helper Task: Configure a Symbol
    // ------------------------------------------------
    task configure_symbol(input [7:0] sym, input [3:0] len, input [15:0] code);
        begin
            @(posedge clk);
            wr_en = 1;
            addr_config = sym;
            data_config = {len, code}; // Pack length and code
            @(posedge clk);
            wr_en = 0;
        end
    endtask

    // ------------------------------------------------
    // Helper Task: Send a Symbol to Stream
    // ------------------------------------------------
    task send_symbol(input [7:0] sym);
        begin
            // Wait until DUT is ready to accept data
            wait(symbol_ready);
            
            @(posedge clk);
            symbol_valid = 1;
            symbol_in = sym;
            
            @(posedge clk);
            symbol_valid = 0;
            symbol_in = 0; // Clean up
        end
    endtask

endmodule