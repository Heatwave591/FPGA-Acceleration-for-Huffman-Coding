# Decoder Reference (`Decoder`)

## Ports

| Signal | Dir | Width | Purpose |
|---|---|---|---|
| `clk`, `rst` | in | 1 | Clock and active-low reset |
| `wr_en` | in | 1 | When high, next clock writes to whichever table `table_sel` points to |
| `table_sel` | in | 2 | `0` = `first_code`, `1` = `base`, `2` = `symbol_table` |
| `addr_config` | in | 8 | Row to write |
| `data_config` | in | 16 | Value to write |
| `stream_in` | in | 32 | Compressed word from the encoder |
| `stream_valid` | in | 1 | Encoder asserts: "I have 32 bits for you" |
| `stream_ready` | out | 1 | Decoder asserts: "I have room, send it" |
| `symbol_out` | out | 8 | The decoded ASCII character |
| `symbol_valid` | out | 1 | Decoder asserts: "symbol_out is valid right now" |
| `symbol_ready` | in | 1 | Testbench asserts: "I'm reading symbol_out" |

---

## Internal State

| Variable | Width | What it holds |
|---|---|---|
| `bit_window` | 64 | Sliding window. Incoming bits land at the top (MSB end). Decoding always reads from the top |
| `bit_count` | 7 | How many valid bits are in `bit_window` right now |
| `first_code[1:16]` | 16-bit × 16 | The **left-justified** first canonical code of each length. e.g. `first_code[2] = 0x8000` represents the 2-bit code `10` stored as `1000000000000000` |
| `base[1:16]` | 16-bit × 16 | Starting index into `symbol_table` for each code length. e.g. `base[2] = 1` |
| `symbol_table[0:255]` | 8-bit × 256 | Maps a flat index → actual ASCII character |
| `peek` | 16 | Always `bit_window[63:48]` — the 16 MSBs you are currently trying to decode |
| `length` | 5 | Result of the length-detection loop |
| `index` | 16 | `base[length] + ((peek - first_code[length]) >> (16 - length))` |
| `next_window` / `next_count` | 64 / 7 | Next-state wires computed in `always_comb`, registered in `always_ff` |

---

## How a Symbol Gets Decoded (Step by Step)

1. **Load** — when `stream_valid && stream_ready`:
   ```
   bit_window |= stream_in << (32 - bit_count)
   bit_count  += 32
   ```
   The incoming 32-bit word is placed MSB-aligned into the window.

2. **Peek** — `peek = bit_window[63:48]` always reflects the front of the queue.

3. **Length detect** — combinational loop from L = 1 to 16:
   ```
   for L in 1..16:
       if peek >= first_code[L]: length = L
   ```
   The last L that satisfies the condition is the code length.

4. **Index** — compute position in symbol_table:
   ```
   index = base[length] + ((peek - first_code[length]) >> (16 - length))
   ```

5. **Lookup** — `symbol_out = symbol_table[index]`

6. **Consume** — when `symbol_valid && symbol_ready`:
   ```
   bit_window <<= length
   bit_count  -= length
   ```

---

## Table Configuration Order

Always write tables in this order:

```
table_sel = 0  →  write first_code[1..16]   (left-justified codes, sentinel 0xFFFF for unused lengths)
table_sel = 1  →  write base[1..16]
             ↑ wait one extra clock here before changing table_sel
table_sel = 2  →  write symbol_table[0..N]
```

> **Critical:** Do not change `table_sel` on the same cycle as the last write to the current table. The write uses the clock edge — if `table_sel` changes too early, the write goes to the wrong table.

---

## Handshake Logic

```
stream_ready = (bit_count <= 32)   — has room for another 32-bit word
symbol_valid = (bit_count >= 1)    — has at least one bit to decode
```

---

## What to Watch in the Waveform

| Signal | What "working" looks like |
|---|---|
| `bit_count` | Jumps up by 32 when a word arrives, ticks down by code length per symbol |
| `peek` | Never X after the first word loads |
| `stream_ready` | High whenever `bit_count <= 32` |
| `symbol_valid` | Stays high while `bit_count >= 1` |
| `symbol_out` | Cycles `0x41 (A) → 0x42 (B) → 0x43 (C)` repeatedly |

---

## Sanity Checks

1. `bit_count` is never X after reset → always_comb/ff split is correct
2. `peek` is non-zero after the first stream word arrives → window loading is correct
3. `symbol_out` is never X → `base[2]` was written correctly (timing bug check)
4. `symbol_out` cycles `41 → 42 → 43` → full round-trip is correct
