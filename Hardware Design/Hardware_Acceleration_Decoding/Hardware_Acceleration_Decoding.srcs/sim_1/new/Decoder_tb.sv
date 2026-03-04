`timescale 1ns/1ps

module decoder_tb;

    // -----------------------------
    // Clock / Reset
    // -----------------------------

    logic clk;
    logic rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // -----------------------------
    // Config Interface
    // -----------------------------

    logic wr_en;
    logic [1:0] table_sel;
    logic [7:0] addr_config;
    logic [15:0] data_config;

    // -----------------------------
    // Stream Interface
    // -----------------------------

    logic [31:0] stream_in;
    logic stream_valid;
    logic stream_ready;

    // -----------------------------
    // Decoder Output
    // -----------------------------

    logic [7:0] symbol_out;
    logic symbol_valid;
    logic symbol_ready;

    // -----------------------------
    // DUT
    // -----------------------------

    Decoder dut (
        .clk(clk),
        .rst(rst),

        .wr_en(wr_en),
        .table_sel(table_sel),
        .addr_config(addr_config),
        .data_config(data_config),

        .stream_in(stream_in),
        .stream_valid(stream_valid),
        .stream_ready(stream_ready),

        .symbol_out(symbol_out),
        .symbol_valid(symbol_valid),
        .symbol_ready(symbol_ready)
    );

    // -----------------------------
    // Test Sequence
    // -----------------------------

    initial begin

        rst = 0;
        wr_en = 0;
        stream_valid = 0;
        symbol_ready = 1;

        #20;
        rst = 1;

        // -----------------------------
        // Load first_code table
        // -----------------------------

        write_table(2'd0, 8'd1, 16'd0);
        write_table(2'd0, 8'd2, 16'd2);
        write_table(2'd0, 8'd3, 16'd6);

        // -----------------------------
        // Load base table
        // -----------------------------

        write_table(2'd1, 8'd1, 16'd0);
        write_table(2'd1, 8'd2, 16'd1);
        write_table(2'd1, 8'd3, 16'd3);

        // -----------------------------
        // Load symbol table
        // -----------------------------

        write_symbol(8'd0, "A");
        write_symbol(8'd1, "B");
        write_symbol(8'd2, "C");

        #20;

        // -----------------------------
        // Send compressed stream
        // -----------------------------

        send_stream(32'b01011000000000000000000000000000);

        #200;

        $finish;

    end


    // ==================================================
    // TASKS
    // ==================================================

    task write_table;
        input logic [1:0] tbl;
        input logic [7:0] addr;
        input logic [15:0] data;
    begin
        @(posedge clk);

        wr_en       = 1;
        table_sel   = tbl;
        addr_config = addr;
        data_config = data;

        @(posedge clk);

        wr_en = 0;
    end
    endtask


    task write_symbol;
        input logic [7:0] addr;
        input logic [7:0] sym;
    begin
        @(posedge clk);

        wr_en       = 1;
        table_sel   = 2;
        addr_config = addr;
        data_config = sym;

        @(posedge clk);

        wr_en = 0;
    end
    endtask


    task send_stream;
        input logic [31:0] data;
    begin
        @(posedge clk);

        stream_valid = 1;
        stream_in    = data;

        @(posedge clk);

        stream_valid = 0;
    end
    endtask


endmodule