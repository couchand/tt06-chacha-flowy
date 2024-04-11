/*
 * Copyright (c) 2024 Andrew Dona-Couch
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module quarter #(
    parameter a_init = 32'b0,
    parameter addr_hi = 2'b0
)(
    input  wire       clk,      // clock
    input  wire       rst_n,    // reset_n - low to reset
    input  wire       hold,     // Set high to pause calculation
    input  wire       write,    // Write input data
    input  wire [5:0] addr_in,  // Block data address input
    input  wire [7:0] data_in,  // Input data bus
    output wire [7:0] data_out  // Block data output bus
);

  reg [31:0] a, b, c, d;

  wire [1:0] addr_row = addr_in[5:4];
  wire [1:0] addr_col = addr_in[3:2];
  wire [1:0] addr_byte = addr_in[1:0];

  wire [31:0] current_word = addr_row == 0 ? a
    : addr_row == 1 ? b
    : addr_row == 2 ? c
    : d;

  assign data_out = addr_col != addr_hi ? 0
    : addr_byte == 0 ? current_word[7:0]
    : addr_byte == 1 ? current_word[15:8]
    : addr_byte == 2 ? current_word[23:16]
    : current_word[31:24];

  always @(posedge clk) begin
    if (!rst_n) begin
        a <= a_init;
        b <= 0;
        c <= 0;
        d <= 0;
    end else if (write && addr_col == addr_hi) begin
      // n.b. never need to write a words
      if (addr_row == 1) begin
        if (addr_byte == 0) b[7:0] <= data_in;
        if (addr_byte == 1) b[15:8] <= data_in;
        if (addr_byte == 2) b[23:16] <= data_in;
        if (addr_byte == 3) b[31:24] <= data_in;
      end else if (addr_row == 2) begin
        if (addr_byte == 0) c[7:0] <= data_in;
        if (addr_byte == 1) c[15:8] <= data_in;
        if (addr_byte == 2) c[23:16] <= data_in;
        if (addr_byte == 3) c[31:24] <= data_in;
      end else if (addr_row == 3) begin
        if (addr_byte == 0) d[7:0] <= data_in;
        if (addr_byte == 1) d[15:8] <= data_in;
        if (addr_byte == 2) d[23:16] <= data_in;
        if (addr_byte == 3) d[31:24] <= data_in;
      end
    end
  end

endmodule
