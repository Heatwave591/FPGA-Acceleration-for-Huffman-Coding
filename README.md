# FPGA Acceleration for Huffman Coding

A hardware-accelerated Huffman compression pipeline implemented in synthesizable SystemVerilog, targeting Xilinx FPGA devices. Designed to accelerate gradient compression for distributed LLM training over high-speed gRPC links.

---

## Overview

This project implements a complete encode-decode Huffman compression pipeline in SystemVerilog, comprising:

- **Huffman Encoder** — accepts 8-bit input symbols, performs a BRAM-based lookup, and packs variable-length codes MSB-first into a 64-bit accumulator, outputting a 32-bit compressed stream.
- **Huffman Decoder** — reconstructs the original symbol sequence from the compressed stream using three canonical lookup tables (`first_code`, `base`, `symbol_table`) and a 64-bit sliding window.
- **Valid/Ready Handshake Interface** — AXI-stream-like flow control between encoder and decoder with zero data loss under backpressure.

Both modules support fully **runtime-configurable Huffman tables** — no RTL recompilation is needed between different codebooks.

---

## Performance

| Metric | Value |
|---|---|
| Clock Frequency (post P&R) | 146 MHz |
| Throughput | 1 symbol/cycle |
| Alphabet Size | 256 symbols (8-bit) |
| Accumulator Width | 64 bits |
| Output Stream Width | 32 bits |

---

## Gradient Compression Results

Three gradient distribution scenarios were evaluated to model different stages of LLM training:

| Scenario | FREQS[0x00] | Avg Code Length | Compression Ratio |
|---|---|---|---|
| Highly Sparse | 10,000 | 3.314 bits | 2.41× |
| Moderate | 1,000 | 5.908 bits | 1.35× |
| Dense | 100 | 7.862 bits | 1.02× |

### Impact on GPT-2 Gradient Transfer (248 MB, 1 Gbps gRPC link)

| Scenario | Compressed Size | Transfer Time | Time Saved | Reduction |
|---|---|---|---|---|
| Highly Sparse (2.41×) | 103 MB | 823 ms | 1161 ms | 58.5% |
| Moderate (1.35×) | 184 MB | 1470 ms | 514 ms | 25.9% |
| Dense (1.02×) | 243 MB | 1945 ms | 39 ms | 2.0% |
| No Compression | 248 MB | 1984 ms | — | — |

---

## Repository Structure

```
FPGA-Acceleration-for-Huffman-Coding/
│
├── Hardware Design/
│   ├── Hardware_Acceleration_Encoding/   # Encoder Vivado project
│   ├── Hardware_Acceleration_Decoding/   # Decoder Vivado project
│   └── Huffman_System_Test/              # Full system testbench Vivado project
│
├── compute_huffman_highly_sparse.py      # Codebook generation - sparse scenario
├── compute_huffman_moderate.py           # Codebook generation - moderate scenario
├── compute_huffman_dense.py              # Codebook generation - dense scenario
│
└── README.md
```

---

## How to Run

### 1. Generate Huffman Tables

Run one of the Python scripts to generate `huffman_tables.svh` for the desired scenario:

```bash
python compute_huffman_highly_sparse.py   # 2.41x compression
python compute_huffman_moderate.py        # 1.35x compression
python compute_huffman_dense.py           # 1.02x compression
```

Each script outputs:
- Average code length
- Compression ratio
- `huffman_tables.svh` — SystemVerilog header loaded by the testbench at runtime

### 2. Run Simulation in Vivado

1. Open the `Huffman_System_Test` project in Vivado 2024
2. Ensure `huffman_tables.svh` is in the project include path
3. Run Behavioural Simulation
4. Verify `symbol_out` matches `symbol_in` for every transmitted symbol

No RTL modifications are required between scenarios — swap the `.svh` file and re-run.

---

## Key Design Decisions

- **MSB-first bit packing** — encoder and decoder both operate MSB-first for correct canonical code alignment
- **always_comb / always_ff split** — eliminates X-propagation issues in Vivado xsim
- **Runtime-configurable tables** — codebook loaded via a write interface at simulation start, no recompilation needed
- **64-bit accumulator** — provides enough headroom for maximum-length codes before flushing a 32-bit output word

---

## Tools & Technologies

- **Language:** SystemVerilog (IEEE 1800-2017)
- **Simulator/Synthesiser:** Vivado 2024
- **Target Device:** Xilinx 7-series FPGA
- **Table Generation:** Python 3 (heapq-based canonical Huffman)

---

## References

1. D. A. Huffman, "A method for the construction of minimum-redundancy codes," *Proc. IRE*, vol. 40, no. 9, pp. 1098–1101, 1952.
2. Canonical Huffman code — [Wikipedia](https://en.wikipedia.org/wiki/Canonical_Huffman_code)
3. Y. Lin et al., "Deep Gradient Compression," *ICLR*, 2018.
4. A. Radford et al., "Language Models are Unsupervised Multitask Learners," OpenAI, 2019.

---

## Author

**Anirudhhan Raghuraman**
Masters in Electrical and Computer Engineering, The Ohio State University
AI EDGE — NSF Institute for Future Edge Networks and Distributed Intelligence
