/*
 * Copyright (c) 2024 Andrew Dona-Couch
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module chacha (
    input  wire       clk,      // clock
    input  wire       rst_n,    // reset_n - low to reset
    input  wire       wr_key,   // Set high to start writing key material
    input  wire       wr_nnc,   // Set high to start writing nonce value
    input  wire       wr_ctr,   // Set high to start writing counter value
    output reg        blk_ready,// Goes high when the next block is available
    input  wire       rd_blk,   // Set high to start reading block data
    input  wire [7:0] data_in,  // Key, nonce, and counter input bus
    output wire [7:0] data_out  // Block data output bus
);

  reg [5:0] addr_counter;

  wire [7:0] col0_out;
  quarter #(
    .a_init(32'h61707865),
    .addr_hi(2'b00)
  ) col0 (
    .clk(clk),
    .rst_n(rst_n),
    .addr_in(addr_counter),
    .data_out(col0_out)
  );

  wire [7:0] col1_out;
  quarter #(
    .a_init(32'h3320646E),
    .addr_hi(2'b01)
  ) col1 (
    .clk(clk),
    .rst_n(rst_n),
    .addr_in(addr_counter),
    .data_out(col1_out)
  );

  assign data_out = col0_out | col1_out;

  always @(posedge clk) begin
    if (!rst_n) begin
        blk_ready <= 0;
        addr_counter <= 0;
    end else if (rd_blk) begin
        addr_counter <= addr_counter + 1;
    end else if (!blk_ready) begin
        blk_ready <= 1;
    end
  end

endmodule
