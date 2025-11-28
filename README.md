# ALU — Parameterized Verilog Implementation

A modular Arithmetic Logic Unit written in Verilog, featuring clean gate-level abstractions, arithmetic cores, combinational and sequential ALU variants, and a full suite of testbenches with waveform output.

---

## Features

- **Modular Gates:** 1-bit and n-bit logic gates (AND/OR/XOR/NOT) with scalable builders
- **Arithmetic Cores:** Add/subtract, logical & arithmetic shift units, comparators
- **ALU Variants:**
  - `combinational_alu` — single-cycle operations
  - `sequential_alu` — FSM controller with latched outputs
- **Testbenches:**
  - Unit tests for each gate and arithmetic core file
  - Integration tests for ALU operations and opcode sequences
- **Makefile Support:** Simple build, clean, and run targets
- **Documentation:** LaTeX reports and diagrams stored under `/docs`

---

## Repository Layout

| Directory | Description |
|----------|-------------|
| `/src`   | Verilog source modules (gates, arithmetic cores, ALUs, etc.) |
| `/tb`    | HDL testbenches and VCD output generation |
| `/out`   | Generated waveforms and simulation artifacts |
| `/docs`  | Reports, diagrams, and course documentation |

---

## Build & Run

Requirements:
- `iverilog`
- `vvp`
- `gtkwave` (optional, for waveform viewing)

```bash
# Compile and run all testbenches
make

# Clean build artifacts
make clean

# View a waveform
gtkwave out/waveforms/<target_file>.vcd
```
## Flag and Semantics
The ALU produces a standard set of condition flags:
- **Z(Zero)**: Result is zero
- **N(Negative)**: Result is negative
- **C(Carry/Borrow)**: Includes *Add* for "carry-out" of MSB and *Sub* for "not-borrowed" semantics
- **V(Overflow)**: Two's-complement signed overflow
These flags are available in both combinational and sequential variants.

## Testing and Verification
- **Unit Tests**: Each gate and arithmetic core has its own dedicated testbench
- **Integration Tests**: Full ALU sequences validated against expected opcode behavior
- **Waveform Output**: Simulation results stored in `\out` as `.vcd` files (viewed through GTKWave or similar program)

## License
Licensed under the MIT License. See `LICENSE` for details
