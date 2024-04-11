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

  dut.ena.value = 1
  dut.ui_in.value = 0

  # Test Initialization
  dut._log.info("Initialization Test")

  # Set hold to prevent calculation
  dut.uio_in.value = 0b00010000

  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 10)

  # Set write key
  dut.uio_in.value = 0b00010001

  # Input key material
  for i in range(1, 33):
    dut.ui_in.value = i & 31
    await ClockCycles(dut.clk, 1)

    if i == 1:
      dut.uio_in.value = 0b00010000

  await ClockCycles(dut.clk, 10)

  # Set write nonce
  dut.uio_in.value = 0b00010010

  # Input nonce value
  for i in range(0x70, 0x78):
    dut.ui_in.value = i
    await ClockCycles(dut.clk, 1)

    if i == 0x70:
      dut.uio_in.value = 0b00010000

  await ClockCycles(dut.clk, 10)

  # Set write counter
  dut.uio_in.value = 0b00010100

  # Input counter value
  for i in range(0xE8, 0xF0):
    dut.ui_in.value = i
    await ClockCycles(dut.clk, 1)

    if i == 0xE8:
      dut.uio_in.value = 0b00010000

  await ClockCycles(dut.clk, 10)

  # Read initial state
  dut._log.info("Read Initial State")
  dut.uio_in.value = 0b00011000
  await ClockCycles(dut.clk, 1)
  dut.uio_in.value = 0b00010000

  assert dut.uo_out.value == b'e'[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'x'[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'p'[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'a'[0]

  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'n'[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'd'[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b' '[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'3'[0]

  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'2'[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'-'[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'b'[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'y'[0]

  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b't'[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'e'[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b' '[0]
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == b'k'[0]

  for i in range(1, 32):
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == i

  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0

  for i in range(0xE8, 0xF0):
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == i

  for i in range(0x70, 0x78):
    await ClockCycles(dut.clk, 1)
    assert dut.uo_out.value == i

  # Now test a block
  dut._log.info("Block Test")

  # Clear hold to allow calculation
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
  dut.uio_in.value = 0b00000000

  assert dut.uo_out.value == 0x76
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0xB8
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0xE0
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0xAD
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0xA0
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0xF1
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x3D
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x90
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x40
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x5D
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x6A
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0xE5
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x53
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x86
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0xBD
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x28
  await ClockCycles(dut.clk, 1)
  # TODO: assert the rest of them?
  await ClockCycles(dut.clk, 48)

  await ClockCycles(dut.clk, 10)

  # The chip proceeds to calculate the next block
  dut._log.info("Await Ready")
  while dut.uio_out.value & 0b10000000 == 0:
    await ClockCycles(dut.clk, 10)


  # Read block
  dut._log.info("Read Block")
  dut.uio_in.value = 0b00001000
  await ClockCycles(dut.clk, 1)
  dut.uio_in.value = 0b00000000

  assert dut.uo_out.value == 0x9F
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x07
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0xE7
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0xBE
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x55
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x51
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x38
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x7A
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x98
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0xBA
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x97
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x7C
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x73
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x2D
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x08
  await ClockCycles(dut.clk, 1)
  assert dut.uo_out.value == 0x0D
  await ClockCycles(dut.clk, 1)
  # TODO: assert the rest of them?
  await ClockCycles(dut.clk, 48)
