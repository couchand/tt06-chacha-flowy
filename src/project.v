/*
 * Copyright (c) 2024 Andrew Dona-Couch
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_couchand_chacha_flowy (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire [7:0] data_in = ui_in;
  wire [7:0] data_out;
  assign uo_out = data_out;

  assign uio_oe = 8'b10000000;

  assign uio_out[6:0] = 0;
  assign uio_out[7] = blk_ready;
  wire blk_ready;

  wire wr_key = uio_in[0];
  wire wr_nnc = uio_in[1];
  wire wr_ctr = uio_in[2];
  wire rd_blk = uio_in[3];
  wire hold = uio_in[4];
  wire [2:0] _ignored1 = uio_in[7:5];
  wire _ignored2 = ena;

  chacha module_instance (
    .clk(clk),
    .rst_n(rst_n),
    .wr_key(wr_key),
    .wr_nnc(wr_nnc),
    .wr_ctr(wr_ctr),
    .hold(hold),
    .rd_blk(rd_blk),
    .blk_ready(blk_ready),
    .data_in(data_in),
    .data_out(data_out)
  );

endmodule
