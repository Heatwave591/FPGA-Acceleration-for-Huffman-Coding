`timescale 1ns/1ps

module system_tb;

logic clk;
logic rst;

// Encoder interfacign
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


// Testing 
initial begin

    rst = 0;
    symbol_valid = 0;
    symbol_ready_out = 1;
    enc_wr_en = 0;
    dec_wr_en = 0;

    #20;
    rst = 1;

    // Load Huffman tables into encoder and decoder
    config_encoder();
    config_decoder();

    // Send enough symbols to fill 32-bit stream word
    // A=2bits, B=1bit, C=2bits → 5 bits per triple → 7 triples = 35 bits
    repeat(7) begin
        send_symbol("A");
        send_symbol("B");
        send_symbol("C");
    end

    #500;

    $finish;

end


// -----------------------
// Config encoder
//
// Huffman codes:
//   Symbol | Code | Length
//   B      | 0    | 1
//   A      | 10   | 2
//   C      | 11   | 2
//
// data_config format: {length[3:0], code[15:0]}
// -----------------------

task config_encoder();
begin

    enc_wr_en = 1;

    @(posedge clk);
    enc_addr_config = 8'h41;            // 'A'
    enc_data_config = {4'd2, 16'd2};    // code=0b10, length=2

    @(posedge clk);
    enc_addr_config = 8'h42;            // 'B'
    enc_data_config = {4'd1, 16'd0};    // code=0b0,  length=1

    @(posedge clk);
    enc_addr_config = 8'h43;            // 'C'
    enc_data_config = {4'd2, 16'd3};    // code=0b11, length=2

    @(posedge clk);
    enc_wr_en = 0;

end
endtask


// -----------------------
// Config decoder
//
// Canonical Huffman tables:
//   length | first_code | base | symbols in order
//   1      | 0          | 0    | B
//   2      | 2          | 1    | A, C
//
// table_sel: 0=first_code, 1=base, 2=symbol_table
// -----------------------

task config_decoder();
integer i;
begin

    dec_wr_en = 1;

    // --- first_code table ---
    dec_table_sel = 2'd0;

    @(posedge clk);
    dec_addr_config = 8'd1;
    dec_data_config = 16'd0;        // first_code[1] = 0  (B)

    @(posedge clk);
    dec_addr_config = 8'd2;
    dec_data_config = 16'h8000;     // first_code[2] = 0x8000  (A = 0b10, left-justified)

    // Remaining lengths: set to 0xFFFF so they never match
    for (i = 3; i <= 16; i = i + 1) begin
        @(posedge clk);
        dec_addr_config = 8'(i);
        dec_data_config = 16'hFFFF;
    end

    // --- base table ---
    dec_table_sel = 2'd1;

    @(posedge clk);
    dec_addr_config = 8'd1;
    dec_data_config = 16'd0;        // base[1] = 0  (B at index 0)

    @(posedge clk);
    dec_addr_config = 8'd2;
    dec_data_config = 16'd1;        // base[2] = 1  (A at index 1, C at index 2)

    @(posedge clk);                 // extra clock to let base[2] write complete

    // --- symbol_table ---
    dec_table_sel = 2'd2;

    @(posedge clk);
    dec_addr_config = 8'd0;
    dec_data_config = 16'h42;       // symbol_table[0] = 'B'

    @(posedge clk);
    dec_addr_config = 8'd1;
    dec_data_config = 16'h41;       // symbol_table[1] = 'A'

    @(posedge clk);
    dec_addr_config = 8'd2;
    dec_data_config = 16'h43;       // symbol_table[2] = 'C'

    @(posedge clk);
    dec_wr_en = 0;

end
endtask


// -----------------------
// Task to send symbols
// -----------------------

task send_symbol(input [7:0] sym);
begin

    @(posedge clk);

    symbol_in    = sym;
    symbol_valid = 1;

    wait(symbol_ready);

    @(posedge clk);

    symbol_valid = 0;

end
endtask

endmodule
