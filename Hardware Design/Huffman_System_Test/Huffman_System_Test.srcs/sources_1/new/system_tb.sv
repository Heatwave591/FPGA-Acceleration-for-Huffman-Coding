`timescale 1ns/1ps

module system_tb;

logic clk;
logic rst;

// Encoder interfacing
logic [7:0]  symbol_in;
logic        symbol_valid;
logic        symbol_ready;

logic [31:0] stream_out;
logic        stream_valid;
logic        stream_ready;

// Encoder config
logic        enc_wr_en;
logic [7:0]  enc_addr_config;
logic [19:0] enc_data_config;

// Decoder interfacing
logic [7:0]  symbol_out;
logic        symbol_valid_out;
logic        symbol_ready_out;

// Decoder config
logic        dec_wr_en;
logic [1:0]  dec_table_sel;
logic [7:0]  dec_addr_config;
logic [15:0] dec_data_config;


initial clk = 0;
always #5 clk = ~clk;


// Encoder
huffman_encoder encoder (
    .clk(clk),
    .rst(rst),

    .wr_en(enc_wr_en),
    .addr_config(enc_addr_config),
    .data_config(enc_data_config),

    .symbol_in(symbol_in),
    .symbol_valid(symbol_valid),
    .symbol_ready(symbol_ready),

    .stream_out(stream_out),
    .stream_valid(stream_valid),
    .stream_ready(stream_ready)
);


// Decoder
Decoder decoder (
    .clk(clk),
    .rst(rst),

    .wr_en(dec_wr_en),
    .table_sel(dec_table_sel),
    .addr_config(dec_addr_config),
    .data_config(dec_data_config),

    .stream_in(stream_out),
    .stream_valid(stream_valid),
    .stream_ready(stream_ready),

    .symbol_out(symbol_out),
    .symbol_valid(symbol_valid_out),
    .symbol_ready(symbol_ready_out)
);


// ── Auto-generated Huffman config tasks (run compute_huffman.py to regenerate)
`include "huffman_tables.svh"


// ── Send one byte through the encoder ────────────────────────────────────────
task send_byte(input [7:0] b);
begin
    @(posedge clk);
    symbol_in    = b;
    symbol_valid = 1;
    wait(symbol_ready);
    @(posedge clk);
    symbol_valid = 0;
end
endtask


// ── Main test sequence ────────────────────────────────────────────────────────
initial begin

    // Initialise
    rst            = 0;
    symbol_valid   = 0;
    symbol_ready_out = 1;
    enc_wr_en      = 0;
    dec_wr_en      = 0;

    #20;
    rst = 1;

    // Load 256-entry Huffman tables into encoder and decoder
    // (config_encoder_full and config_decoder_full come from huffman_tables.svh)
    config_encoder_full();
    config_decoder_full();

    // ── Test vector: gradient-like byte sequence ──────────────────────────
    // Simulates a small bfloat16 gradient chunk:
    //   many zero bytes (sparse gradient), a few small-value exponent bytes.
    // After round-trip through encoder → decoder, symbol_out must reproduce
    // the same sequence in order.
    //
    //  0x00 = zero byte      (very common in sparse gradients)
    //  0x3F = small +ve bf16 exponent
    //  0xBF = small -ve bf16 exponent
    //  0x80 = negative zero
    //  0x40 = slightly larger +ve
    //
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'h3F);   // small positive value
    send_byte(8'h80);
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'hBF);   // small negative value
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'h40);   // slightly larger positive
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'h80);
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'h3F);
    send_byte(8'h00);
    send_byte(8'h00);

    repeat(32) send_byte(8'h00);
    // Wait long enough for the decoder to drain all stream words
    #10000;

    $finish;

end

endmodule
