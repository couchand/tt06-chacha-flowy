<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

A hardware ChaCha generator.

## How it works

The state is stored within four parallel quarter rounds.  Each computes one "column" of the state for each round.  Between rounds, the words are shifted among the parallel columns to compute "diagonal" rounds.

## How to test

1. Select the design and reset the chip.
2. Put the first byte of key material on the input data bus and bring `wr_key` high for at least one clock cycle.
3. Continue clocking in the 32 bytes of key material.
4. Put the first byte of the nonce value on the data bus and bring `wr_nnc` high for at least one clock cycle.
5. Continue clocking in the 8 bytes of nonce value.
6. If desired, put the first byte of the initial counter value on the bus and bring `wr_ctr` high for at least one clock cycle.
7. Continue clocking in the 8 bytes of counter value, if applicable.
8. Wait for the `blk_ready` line to go high, indicating that the next block is ready.
9. The first byte of the block is available on the output data bus.  Bring `rd_blk` high for at least one clock cycle.
10. Continue clocking out the 64 bytes of block value.
11. Loop back to step number 8, awaiting the next block.

## External hardware

The ChaCha cipher is defined as an XOR of the block data with the plaintext value, so you should arrange for the output data bus to be XORed with your plaintext data bus.  You'll want to set up a 64-byte buffer that can clock out a block-sized chunk of the message, when it's ready from the chip.

Since XOR is symmetric, the same setup can be used to decrypt a message by clocking the ciphertext through the message bus.
