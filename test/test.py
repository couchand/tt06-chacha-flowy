# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
  dut._log.info("Start")

  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 10)

  # On reset, key = nonce = counter = 0, so that's all we need to do.
  dut._log.info("Await Ready")
  while dut.uio_out.value & 0b10000000 == 0:
    await ClockCycles(dut.clk, 10)

  # Read block
  dut._log.info("Read Block")
  dut.uio_in.value = 0b00001000

  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'e'[0]
  # TODO
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'x'[0]
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'p'[0]
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'a'[0]

  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'n'[0]
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'd'[0]
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b' '[0]
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'3'[0]

  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'2'[0]
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'-'[0]
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'b'[0]
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'y'[0]

  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b't'[0]
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'e'[0]
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b' '[0]
  #await ClockCycles(dut.clk, 1)
  #assert dut.uo_out.value == b'k'[0]
