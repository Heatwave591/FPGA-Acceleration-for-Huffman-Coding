`timescale 1ns/1ps

module system_tb;

logic clk;
logic rst;

// -----------------------
// Encoder interface
// -----------------------

logic [7:0] symbol_in;
logic symbol_valid;
logic symbol_ready;

logic [31:0] stream_out;
logic stream_valid;
logic stream_ready;

// -----------------------
// Decoder interface
// -----------------------

logic [7:0] symbol_out;
logic symbol_valid_out;
logic symbol_ready_out;


// -----------------------
// Clock
// -----------------------

initial clk = 0;
always #5 clk = ~clk;


// -----------------------
// Encoder
// -----------------------

huffman_encoder encoder (

    .clk(clk),
    .rst(rst),

    .symbol_in(symbol_in),
    .symbol_valid(symbol_valid),
    .symbol_ready(symbol_ready),

    .stream_out(stream_out),
    .stream_valid(stream_valid),
    .stream_ready(stream_ready)
);


// -----------------------
// Decoder
// -----------------------

Decoder decoder (

    .clk(clk),
    .rst(rst),

    .stream_in(stream_out),
    .stream_valid(stream_valid),
    .stream_ready(stream_ready),

    .symbol_out(symbol_out),
    .symbol_valid(symbol_valid_out),
    .symbol_ready(symbol_ready_out)
);


// -----------------------
// Test
// -----------------------

initial begin

    rst = 0;
    symbol_valid = 0;
    symbol_ready_out = 1;

    #20;
    rst = 1;

    // Send symbols
    send_symbol("A");
    send_symbol("B");
    send_symbol("C");
    send_symbol("A");
    send_symbol("B");

    #500;

    $finish;

end


// -----------------------
// Task to send symbols
// -----------------------

task send_symbol(input [7:0] sym);
begin

    @(posedge clk);

    symbol_in = sym;
    symbol_valid = 1;

    wait(symbol_ready);

    @(posedge clk);

    symbol_valid = 0;

end
endtask

endmodule