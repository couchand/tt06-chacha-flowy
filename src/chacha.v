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
    input  wire       hold,     // Set high to pause calculation
    output reg        blk_ready,// Goes high when the next block is available
    input  wire       rd_blk,   // Set high to start reading block data
    input  wire [7:0] data_in,  // Key, nonce, and counter input bus
    output wire [7:0] data_out  // Block data output bus
);

  localparam ST_RESET = 0;
  localparam ST_READING = 1;
  localparam ST_WRITE_KEY = 2;
  localparam ST_WRITE_NNC = 4;
  localparam ST_WRITE_CTR = 8;
  localparam ST_ROUND = 16;

  reg [7:0] state;
  reg [5:0] addr_counter;

  wire writing_key = wr_key | state == ST_WRITE_KEY;
  wire writing_nnc = wr_nnc | state == ST_WRITE_NNC;
  wire writing_ctr = wr_ctr | state == ST_WRITE_CTR;
  wire reading_blk = rd_blk | state == ST_READING;

  wire [5:0] offset = writing_key ? 6'h10
    : writing_nnc ? 6'h30
    : writing_ctr ? 6'h38
    : 0;

  wire [5:0] addr_in = addr_counter + offset;
  wire write = writing_key | writing_nnc | writing_ctr;

  wire calc = ~write & ~reading_blk & ~hold & state == ST_ROUND;
  reg [1:0] step;

  wire [7:0] col0_out;
  quarter #(
    .a_init(32'h61707865),
    .addr_hi(2'b00)
  ) col0 (
    .clk(clk),
    .rst_n(rst_n),
    .calc(calc),
    .step(step),
    .write(write),
    .addr_in(addr_in),
    .data_in(data_in),
    .data_out(col0_out)
  );

  wire [7:0] col1_out;
  quarter #(
    .a_init(32'h3320646E),
    .addr_hi(2'b01)
  ) col1 (
    .clk(clk),
    .rst_n(rst_n),
    .calc(calc),
    .step(step),
    .write(write),
    .addr_in(addr_in),
    .data_in(data_in),
    .data_out(col1_out)
  );

  wire [7:0] col2_out;
  quarter #(
    .a_init(32'h79622D32),
    .addr_hi(2'b10)
  ) col2 (
    .clk(clk),
    .rst_n(rst_n),
    .calc(calc),
    .step(step),
    .write(write),
    .addr_in(addr_in),
    .data_in(data_in),
    .data_out(col2_out)
  );

  wire [7:0] col3_out;
  quarter #(
    .a_init(32'h6B206574),
    .addr_hi(2'b11)
  ) col3 (
    .clk(clk),
    .rst_n(rst_n),
    .calc(calc),
    .step(step),
    .write(write),
    .addr_in(addr_in),
    .data_in(data_in),
    .data_out(col3_out)
  );

  assign data_out = col0_out | col1_out | col2_out | col3_out;

  always @(posedge clk) begin
    if (!rst_n) begin
      blk_ready <= 0;
      addr_counter <= 0;
      state <= ST_ROUND;
      step <= 0;
    end else if (writing_key) begin
      if (addr_counter + 6'b1 == 6'h20) begin
        state <= ST_ROUND;
        step <= 0;
        addr_counter <= 0;
      end else begin
        addr_counter <= addr_counter + 1;
        state <= ST_WRITE_KEY;
      end
    end else if (writing_nnc) begin
      if (addr_counter + 6'b1 == 6'h08) begin
        state <= ST_ROUND;
        step <= 0;
        addr_counter <= 0;
      end else begin
        addr_counter <= addr_counter + 1;
        state <= ST_WRITE_NNC;
      end
    end else if (writing_ctr) begin
      if (addr_counter + 6'b1 == 6'h08) begin
        state <= ST_ROUND;
        step <= 0;
        addr_counter <= 0;
      end else begin
        addr_counter <= addr_counter + 1;
        state <= ST_WRITE_CTR;
      end
    end else if (reading_blk) begin
      if (addr_counter + 6'b1 == 6'b0) begin
        state <= ST_RESET;
        addr_counter <= 0;
      end else begin
        addr_counter <= addr_counter + 1;
        state <= ST_READING;
      end
    end else if (calc) begin
      if (step + 2'b1 == 2'b0) begin
        step <= 0;
        state <= ST_RESET;
      end else begin
        step <= step + 1;
      end
    end
  end

endmodule
