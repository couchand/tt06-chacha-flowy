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
    output wire       blk_ready,// Goes high when the next block is available
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
  localparam ST_SHIFT = 32;
  localparam ST_ADD = 64;
  localparam ST_READY = 128;
  localparam ST_INCREMENT = 256;
  localparam ST_CLEAR = 512;

  reg [9:0] state;
  reg [5:0] addr_counter;

  wire writing_key = wr_key | state == ST_WRITE_KEY;
  wire writing_nnc = wr_nnc | state == ST_WRITE_NNC;
  wire writing_ctr = wr_ctr | state == ST_WRITE_CTR;
  wire reading_blk = rd_blk | state == ST_READING;

  assign blk_ready = state == ST_READY;

  wire [5:0] offset = writing_key ? 6'h10
    : writing_nnc ? 6'h38
    : writing_ctr ? 6'h30
    : 0;

  wire [5:0] addr_in = addr_counter + offset;
  wire write = writing_key | writing_nnc | writing_ctr;

  wire proceed = ~write & ~reading_blk & ~hold;

  wire calc = proceed & state == ST_ROUND;
  wire shift = proceed & state == ST_SHIFT;
  wire add_back = proceed & state == ST_ADD;
  wire inc_ctr = proceed & state == ST_INCREMENT;
  wire clear = ~write & ~reading_blk & state == ST_CLEAR;

  reg [1:0] step;
  reg [4:0] shift_ctr;

  reg [4:0] round;

  wire [7:0] col0_out;
  wire [7:0] col0_shift;
  wire carry;
  quarter #(
    .a_init(32'h61707865),
    .addr_hi(2'b00)
  ) col0 (
    .clk(clk),
    .rst_n(rst_n),
    .calc(calc),
    .add_back(add_back),
    .clear(clear),
    .inc_ctr(inc_ctr),
    .ctr_out(carry),
    .step(step),
    .write(write),
    .addr_in(addr_in),
    .data_in(data_in),
    .data_out(col0_out),
    .shift(shift),
    .shift_dir(round[0]),
    .shift_ctr(shift_ctr),
    .shift_in(col3_shift),
    .shift_out(col0_shift)
  );

  wire [7:0] col1_out;
  wire [7:0] col1_shift;
  quarter #(
    .a_init(32'h3320646E),
    .addr_hi(2'b01)
  ) col1 (
    .clk(clk),
    .rst_n(rst_n),
    .calc(calc),
    .add_back(add_back),
    .clear(clear),
    .inc_ctr(inc_ctr),
    .ctr_in(carry),
    .step(step),
    .write(write),
    .addr_in(addr_in),
    .data_in(data_in),
    .data_out(col1_out),
    .shift(shift),
    .shift_dir(round[0]),
    .shift_ctr(shift_ctr),
    .shift_in(col0_shift),
    .shift_out(col1_shift)
  );

  wire [7:0] col2_out;
  wire [7:0] col2_shift;
  quarter #(
    .a_init(32'h79622D32),
    .addr_hi(2'b10)
  ) col2 (
    .clk(clk),
    .rst_n(rst_n),
    .calc(calc),
    .add_back(add_back),
    .clear(clear),
    .inc_ctr(inc_ctr),
    .step(step),
    .write(write),
    .addr_in(addr_in),
    .data_in(data_in),
    .data_out(col2_out),
    .shift(shift),
    .shift_dir(round[0]),
    .shift_ctr(shift_ctr),
    .shift_in(col1_shift),
    .shift_out(col2_shift)
  );

  wire [7:0] col3_out;
  wire [7:0] col3_shift;
  quarter #(
    .a_init(32'h6B206574),
    .addr_hi(2'b11)
  ) col3 (
    .clk(clk),
    .rst_n(rst_n),
    .calc(calc),
    .add_back(add_back),
    .clear(clear),
    .inc_ctr(inc_ctr),
    .step(step),
    .write(write),
    .addr_in(addr_in),
    .data_in(data_in),
    .data_out(col3_out),
    .shift(shift),
    .shift_dir(round[0]),
    .shift_ctr(shift_ctr),
    .shift_in(col2_shift),
    .shift_out(col3_shift)
  );

  assign data_out = ~(blk_ready | reading_blk) ? 0
    : col0_out | col1_out | col2_out | col3_out;

  always @(posedge clk) begin
    if (!rst_n) begin
      addr_counter <= 0;
      state <= ST_CLEAR;
      shift_ctr <= 0;
      round <= 0;
      step <= 0;
    end else if (writing_key) begin
      if (addr_counter + 6'b1 == 6'h20) begin
        state <= ST_CLEAR;
        addr_counter <= 0;
      end else begin
        addr_counter <= addr_counter + 1;
        state <= ST_WRITE_KEY;
      end
    end else if (writing_nnc) begin
      if (addr_counter + 6'b1 == 6'h08) begin
        state <= ST_CLEAR;
        addr_counter <= 0;
      end else begin
        addr_counter <= addr_counter + 1;
        state <= ST_WRITE_NNC;
      end
    end else if (writing_ctr) begin
      if (addr_counter + 6'b1 == 6'h08) begin
        state <= ST_CLEAR;
        addr_counter <= 0;
      end else begin
        addr_counter <= addr_counter + 1;
        state <= ST_WRITE_CTR;
      end
    end else if (reading_blk) begin
      if (addr_counter + 6'b1 == 6'b0) begin
        state <= ST_INCREMENT;
        addr_counter <= 0;
      end else begin
        addr_counter <= addr_counter + 1;
        state <= ST_READING;
      end
    end else if (calc) begin
      if (step + 2'b1 == 2'b0) begin
        step <= 0;
        state <= ST_SHIFT;
        shift_ctr <= 0;
        round <= round + 1;
      end else begin
        step <= step + 1;
      end
    end else if (shift) begin
      shift_ctr <= shift_ctr + 1;
      if (shift_ctr + 5'b1 == 5'b0) begin
        if (round == 20) begin
          state <= ST_ADD;
        end else begin
          state <= ST_ROUND;
        end
      end
    end else if (add_back) begin
      state <= ST_READY;
      round <= 0;
      step <= 0;
    end else if (inc_ctr) begin
      state <= ST_CLEAR;
    end else if (clear) begin
      state <= ST_ROUND;
      round <= 0;
      step <= 0;
    end
  end

endmodule
