
# Huffman Encoder – Control Flow (Bit Packing Logic)

This document describes the cycle-level control logic of the Huffman Encoder bit-packing module.

The encoder operates on every rising edge of the clock and follows a deterministic decision structure based on:

- `rst`
- `stream_valid`
- `stream_ready`
- `symbol_valid`
- `symbol_ready`
- `bit_count`
- `accumulator`

---

## Top-Level Behavior

All logic executes on:

```
Rising Edge of clk
```

---

## 1. Reset Behavior

### Condition:
```
rst == 0   (Active Low Reset)
```

### Action:
```
accumulator <= 0
bit_count   <= 0
```

The encoder buffer is cleared, and the system returns to an empty state.

---

## 2. Normal Operation (rst == 1)

When reset is released:

```
rst == 1
```

The encoder evaluates output status first.

---

## 3. Check Output Status

### Condition:
```
stream_valid AND stream_ready
```

This means:
- The accumulator has ≥ 32 bits
- The downstream module is ready to accept data

---

### Case A: Output Flush Required

If:

```
bit_count >= 32
```

### Actions:

1. Flush 32 bits from accumulator:
   ```
   stream_out = accumulator[31:0]
   ```

2. Shift accumulator:
   ```
   accumulator = accumulator >> 32
   ```

3. Update bit counter:
   ```
   bit_count = bit_count - 32
   ```

---

### After Flush → Check Input Status

Now check:

```
symbol_valid AND symbol_ready
```

#### If TRUE:
Insert new code immediately after flush:

```
accumulator = accumulator OR (code << bit_count)
bit_count   = bit_count + current_len
```

#### If FALSE:
No accumulation occurs this cycle.

---

## 4. If No Flush Needed

If:

```
NOT (stream_valid AND stream_ready)
```

Then check input side.

### Check Input Status

```
symbol_valid AND symbol_ready
```

### Case B: Only Accumulate

If TRUE:

```
accumulator = accumulator OR (code << bit_count)
bit_count   = bit_count + current_len
```

No flushing occurs.

If FALSE:
Do nothing.

---

## 5. End of Clock Cycle

At the end of the cycle:

```
Repeat same logic at next rising edge
```

System waits until the next clock.

---

# Behavioral Summary

The encoder always prioritizes:

1. Flushing 32-bit words when possible
2. Accumulating new Huffman codes
3. Respecting backpressure from downstream (`stream_ready`)
4. Respecting upstream availability (`symbol_valid`)

---

# Hardware Interpretation

This module behaves as:

- A 64-bit shift-register accumulator
- A 6-bit bit counter
- A streaming handshake controller

It is the core engine of the Huffman compression accelerator.
