# Encoder Reference (`huffman_encoder`)

## Ports

| Signal | Dir | Width | Purpose |
|---|---|---|---|
| `clk`, `rst` | in | 1 | Clock and active-low reset |
| `wr_en` | in | 1 | When high, next clock writes to `code_table` |
| `addr_config` | in | 8 | Which symbol (0x00–0xFF) to write the code for |
| `data_config` | in | 20 | `[19:16]` = code length (1–16), `[15:0]` = the Huffman code |
| `symbol_in` | in | 8 | The ASCII symbol to encode |
| `symbol_valid` | in | 1 | Testbench asserts: "I have a symbol ready" |
| `symbol_ready` | out | 1 | Encoder asserts: "I can accept a symbol" |
| `stream_out` | out | 32 | The compressed output word |
| `stream_valid` | out | 1 | Encoder asserts: "I have 32 packed bits ready" |
| `stream_ready` | in | 1 | Downstream asserts: "take your 32 bits, I'm ready" |

---

## Internal State

| Variable | Width | What it holds |
|---|---|---|
| `code_table[255:0]` | 20-bit × 256 | The Huffman codebook. `code_table[0x41]` = code for 'A' |
| `accumulator` | 64 | Bit-packing buffer. New codes are stuffed in from the MSB end |
| `bit_count` | 6 | How many valid bits are currently sitting in `accumulator` |
| `current_len` / `current_code` | 4 / 16 | Pulled from `code_table[symbol_in]` combinationally |
| `next_acc` / `next_count` | 64 / 6 | Next-state wires computed in `always_comb`, registered in `always_ff` |

---

## How a Symbol Gets Packed

```
accumulator |= current_code << (64 - bit_count - current_len)
```

This pushes the code into the highest free bit slot (MSB-first packing).

Once `bit_count >= 32`:
- `stream_valid` goes high
- `stream_out` = `accumulator[63:32]`
- On handshake: `accumulator <<= 32`, `bit_count -= 32`

---

## Handshake Logic

```
symbol_ready = (bit_count < 32) || stream_ready
stream_valid = (bit_count >= 32)
```

- The encoder can accept a new symbol as long as there is space in the accumulator **or** a flush is happening simultaneously.
- The encoder advertises output as soon as 32 bits are packed.

---

## What to Watch in the Waveform

| Signal | What "working" looks like |
|---|---|
| `bit_count` | **Never X** after reset. Increments by code length each symbol, drops by 32 on flush |
| `symbol_ready` | Stays high as long as `bit_count < 32` |
| `stream_out` | Grows step by step: `0x80000000` → `0x98000000` → ... → `0x9CE739CE` |
| `stream_valid` | Pulses high for **exactly one cycle** when `bit_count` crosses 32 |

---

## Sanity Checks

1. `bit_count` is never X after reset → always_comb/ff split is correct
2. `stream_out` reaches `0x9CE739CE` after 7× (A, B, C) → encoding is correct
3. `stream_valid` pulses for exactly 1 cycle → flush logic is correct
4. After the flush, `stream_out` shows `0x60000000` (residual 3 bits: B=0, C=11)
