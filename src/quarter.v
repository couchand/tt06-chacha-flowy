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
    input  wire       write,    // Write input data
    input  wire       calc,     // Calculate a round
    input  wire       add_back, // Add the inital values back in
    input  wire       clear,    // Reset to the initial values
    input  wire       inc_ctr,  // Increment the block counter
    input  wire       ctr_in,   // Counter carry in
    output wire       ctr_out,  // Counter carry out
    input  wire [1:0] step,     // Which step in a round
    input  wire [5:0] addr_in,  // Block data address input
    input  wire [7:0] data_in,  // Input data bus
    output wire [7:0] data_out, // Block data output bus
    input  wire       shift,    // Shift words for alternate rounds
    input  wire [31:0] shift_in,
    output wire [31:0] shift_out
);

  reg [31:0] b_init, c_init, d_init;
  reg [31:0] a, b, c, d;

  wire [31:0] a_plus_b = a + b;
  wire [31:0] d_xor_apb = d ^ a_plus_b;
  wire [31:0] dxa_rotl_16 = (d_xor_apb << 16) | (d_xor_apb >> 16);
  wire [31:0] dxa_rotl_8 = (d_xor_apb << 8) | (d_xor_apb >> 24);

  wire [31:0] c_plus_d = c + d;
  wire [31:0] b_xor_cpd = b ^ c_plus_d;
  wire [31:0] bxc_rotl_12 = (b_xor_cpd << 12) | (b_xor_cpd >> 20);
  wire [31:0] bxc_rotl_7 = (b_xor_cpd << 7) | (b_xor_cpd >> 25);

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

  assign shift_out = step == 1 ? b
    : step == 2 ? c
    : step == 3 ? d
    : 0;

  assign ctr_out = (addr_hi != 0) ? 0 : d_init == 32'hFFFFFFFF;

  always @(posedge clk) begin
    if (!rst_n) begin
        a <= a_init;
        b <= 0;
        b_init <= 0;
        c <= 0;
        c_init <= 0;
        d <= 0;
        d_init <= 0;
    end else if (write && addr_col == addr_hi) begin
      // n.b. never need to write a words
      if (addr_row == 1) begin
        if (addr_byte == 0) begin
          b_init[7:0] <= data_in;
        end
        if (addr_byte == 1) begin
          b_init[15:8] <= data_in;
        end
        if (addr_byte == 2) begin
          b_init[23:16] <= data_in;
        end
        if (addr_byte == 3) begin
          b_init[31:24] <= data_in;
        end
      end else if (addr_row == 2) begin
        if (addr_byte == 0) begin
          c_init[7:0] <= data_in;
        end
        if (addr_byte == 1) begin
          c_init[15:8] <= data_in;
        end
        if (addr_byte == 2) begin
          c_init[23:16] <= data_in;
        end
        if (addr_byte == 3) begin
          c_init[31:24] <= data_in;
        end
      end else if (addr_row == 3) begin
        if (addr_byte == 0) begin
          d_init[7:0] <= data_in;
        end
        if (addr_byte == 1) begin
          d_init[15:8] <= data_in;
        end
        if (addr_byte == 2) begin
          d_init[23:16] <= data_in;
        end
        if (addr_byte == 3) begin
          d_init[31:24] <= data_in;
        end
      end
    end else if (calc) begin
      if (step == 0) begin
        a <= a_plus_b;
        d <= dxa_rotl_16;
      end else if (step == 1) begin
        b <= bxc_rotl_12;
        c <= c_plus_d;
      end else if (step == 2) begin
        a <= a_plus_b;
        d <= dxa_rotl_8;
      end else if (step == 3) begin
        b <= bxc_rotl_7;
        c <= c_plus_d;
      end
    end else if (shift) begin
      if (step == 1) begin
        b <= shift_in;
      end else if (step == 2) begin
        c <= shift_in;
      end else if (step == 3) begin
        d <= shift_in;
      end
    end else if (add_back) begin
      a <= a + a_init;
      b <= b + b_init;
      c <= c + c_init;
      d <= d + d_init;
    end else if (inc_ctr) begin
      if (addr_hi == 0) begin
        d_init <= d_init + 1;
      end else if (addr_hi == 1) begin
        d_init <= d_init + ctr_in;
      end
    end else if (clear) begin
      a <= a_init;
      b <= b_init;
      c <= c_init;
      d <= d_init;
    end
  end

endmodule
