<div align="center">

# 16-bit Custom Processor — Logisim Implementation

[![Logisim](https://img.shields.io/badge/Logisim-Evolution-blue?style=for-the-badge&logo=circuitverse&logoColor=white)](https://github.com/logisim-evolution/logisim-evolution)
[![Architecture](https://img.shields.io/badge/Architecture-16--bit-orange?style=for-the-badge&logo=processwire&logoColor=white)]()
[![Registers](https://img.shields.io/badge/Registers-8%20×%2016--bit-green?style=for-the-badge&logo=buffer&logoColor=white)]()
[![Status](https://img.shields.io/badge/Status-Complete%20✓-brightgreen?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-Academic-purple?style=for-the-badge)]()

**A fully functional 16-bit processor datapath designed and simulated in Logisim Evolution.**  
Supports arithmetic, logical, memory, and branch instructions — with a working assembly program verified in simulation.

---

<!-- 📸 SCREENSHOT SUGGESTION #1:
     Take a full screenshot of your entire Logisim canvas showing the complete datapath.
     Save it as: screenshots/datapath_overview.png
     It will appear right here as the hero image of your README. -->

Datapath Overview
<img width="902" height="613" alt="image" src="https://github.com/user-attachments/assets/085fc89c-a75a-4fa1-8afe-60c8c51bb9c1" />

</div>

---

##Table of Contents

- [Project Overview](#-project-overview)
- [Processor Specifications](#-processor-specifications)
- [Instruction Set Architecture](#-instruction-set-architecture)
- [Datapath Architecture](#-datapath-architecture)
- [Assembly Program](#-assembly-program)
- [Machine Code](#-machine-code)
- [Simulation Results](#-simulation-results)
- [Repository Structure](#-repository-structure)
- [How to Run](#-how-to-run)
- [Author](#-author)

---

## Project Overview

This project implements a **custom 16-bit processor** from scratch using **Logisim generic**. The processor executes a program that counts array elements **not equal to 5**, stores the result back into Data Memory, and halts.

The design follows the classic **5-stage datapath model**:

```
[ Fetch ] ──► [ Decode ] ──► [ Execute ] ──► [ Memory ] ──► [ Write Back ]
```

---

## Processor Specifications

| Property | Value |
|---|---|
| Word Size | 16 bits |
| Register Count | 8 registers (X0 – X7) |
| Register Width | 16 bits each |
| Instruction Memory | ROM — 256 locations × 16-bit |
| Data Memory | RAM — 256 locations × 16-bit |
| ALU Operations | ADD, SUB, AND, OR |
| Branch Support | BEQ (branch if equal) |
| PC Increment | +1 per cycle (word-addressed) |

---

## Instruction Set Architecture

All instructions are **16 bits wide**, divided into 4 fields:

```
 15      11  10    8   7     5   4        0
┌──────────┬───────┬───────┬─────────────┐
│  Opcode  │  Rd   │  Rs   │  Immediate  │
│  5 bits  │ 3 bit │ 3 bit │   5 bits    │
└──────────┴───────┴───────┴─────────────┘
```

### Supported Instructions

| Opcode (bin) | Opcode (hex) | Mnemonic | Operation | Example |
|:---:|:---:|:---:|---|---|
| `00001` | `01` | **ADDI** | `Rd = Rs + Imm` | `ADDI X1, X0, #8` |
| `00010` | `02` | **SUBI** | `Rd = Rs - Imm` | `SUBI X2, X2, #1` |
| `00011` | `03` | **ANDI** | `Rd = Rs AND Imm` | `ANDI X1, X2, #7` |
| `00100` | `04` | **ORI**  | `Rd = Rs OR Imm` | `ORI X1, X2, #3` |
| `00101` | `05` | **LDR**  | `Rd = Mem[Rs+Imm]` | `LDR X4, [X1, #0]` |
| `00110` | `06` | **STR**  | `Mem[Rs+Imm] = Rd` | `STR X3, [X0, #10]` |
| `00111` | `07` | **BEQ**  | `if Rd==Rs: PC+=Imm` | `BEQ X4, X6, #1` |

### Control Signals Table

| Instruction | RegWrite | ALUSrc | ALUCtrl | MemRead | MemWrite | MemToReg | Branch |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| ADDI | 1 | 1 | 00 | 0 | 0 | 0 | 0 |
| SUBI | 1 | 1 | 01 | 0 | 0 | 0 | 0 |
| ANDI | 1 | 1 | 10 | 0 | 0 | 0 | 0 |
| ORI  | 1 | 1 | 11 | 0 | 0 | 0 | 0 |
| LDR  | 1 | 1 | 00 | 1 | 0 | 1 | 0 |
| STR  | 0 | 1 | 00 | 0 | 1 | 0 | 0 |
| BEQ  | 0 | 0 | 01 | 0 | 0 | 0 | 1 |

---

## Datapath Architecture

The processor is built from the following components, each implemented as a Logisim subcircuit:

```
                ┌─────────────────────────────────────────────────┐
                │                  DATAPATH                       │
                │                                                 │
  ┌──────┐      │  ┌─────────┐    ┌──────────────┐               │
  │Clock │──────┼─►│   PC    │───►│  Instruction │               │
  └──────┘      │  │(16-bit) │    │   Memory     │               │
                │  └────┬────┘    │    (ROM)     │               │
                │       │PC+1     └──────┬───────┘               │
                │       │               │ 16-bit instruction      │
                │  ┌────▼────┐    ┌──────▼───────┐               │
                │  │  +1     │    │   Splitter   │               │
                │  │ Adder   │    │ Opcode|Rd|Rs │               │
                │  └────┬────┘    │    |Imm      │               │
                │       │         └──┬───┬───┬───┘               │
                │  ┌────▼──────┐     │   │   │                   │
                │  │  PC MUX   │◄────┘   │   │ Opcode            │
                │  │(PC+1/Br.) │    ┌────▼───▼──────┐            │
                │  └───────────┘    │  Control Unit │            │
                │                   └───────┬───────┘            │
                │                           │ Control Signals     │
                │  ┌───────────────────────────────────────────┐  │
                │  │             Register File                 │  │
                │  │   X0  X1  X2  X3  X4  X5  X6  X7        │  │
                │  │   (8 × 16-bit registers)                  │  │
                │  └────────────────┬──────────────────────────┘  │
                │                   │ ReadData1 / ReadData2        │
                │  ┌────────────────▼──────────┐                  │
                │  │           ALU             │                  │
                │  │  ADD / SUB / AND / OR     │──► Zero Flag     │
                │  └────────────────┬──────────┘                  │
                │                   │ ALU Result                  │
                │  ┌────────────────▼──────────┐                  │
                │  │       Data Memory         │                  │
                │  │          (RAM)            │                  │
                │  └───────────────────────────┘                  │
                └─────────────────────────────────────────────────┘
```

### Key Components

| Component | Description |
|---|---|
| **Program Counter (PC)** | 16-bit register. Holds current instruction address. Increments by 1 per cycle or jumps on branch. |
| **Instruction Memory** | ROM with 256 × 16-bit locations. Addressed by PC. |
| **Instruction Splitter** | Logisim Splitter. Extracts Opcode[15:11], Rd[10:8], Rs[7:5], Imm[4:0]. |
| **Control Unit** | ROM-based lookup table. Inputs Opcode → outputs 7 control signals. |
| **Register File** | 8 × 16-bit registers (X0–X7). Dual-read, single-write, clock-triggered. |
| **ALU** | Performs ADD, SUB, AND, OR. Outputs Result and Zero flag. |
| **Sign Extender** | Extends 5-bit Immediate to 16-bit (signed). |
| **Data Memory** | RAM 256 × 16-bit. Supports LDR (read) and STR (write). |
| **Branch Logic** | Computes branch target (PC + Imm). Takes branch if BEQ and Zero=1. |

---

## Assembly Program

**Task:** Count elements in an 8-element array that are **not equal to 5**. Store result in RAM.

### Register Map

| Register | Role |
|:---:|---|
| `X0` | Always 0 (zero register) |
| `X1` | RAM address pointer |
| `X2` | Loop counter (counts down from 8) |
| `X3` | Result counter (elements ≠ 5) |
| `X4` | Current array element |
| `X6` | Constant 5 (comparison target) |

### Source Code

```asm
; ============================================================
; 16-bit Processor — Count elements NOT equal to 5
; Author  : Eqbal
; GitHub  : https://github.com/Eqbal-eo
; ============================================================

; --- Initialization ---
0.  ADDI X6, X0, #5     ; X6 = 5  (target comparison value)
1.  ADDI X1, X0, #0     ; X1 = 0  (RAM address pointer, start at 0)
2.  ADDI X2, X0, #8     ; X2 = 8  (loop counter = array length)
3.  ADDI X3, X0, #0     ; X3 = 0  (result counter, elements ≠ 5)

; --- Loop Start ---
4.  BEQ  X2, X0, #6     ; if X2 == 0: EXIT loop (jump to instruction 11)
5.  LDR  X4, [X1, #0]   ; X4 = RAM[X1]  (load current element)
6.  BEQ  X4, X6, #1     ; if X4 == 5: SKIP increment (jump to instruction 8)
7.  ADDI X3, X3, #1     ; X3++  (element is NOT 5, count it)

; --- Loop Update ---
8.  ADDI X1, X1, #1     ; X1++  (advance RAM pointer to next element)
9.  SUBI X2, X2, #1     ; X2--  (decrement loop counter)
10. BEQ  X0, X0, #-7    ; UNCONDITIONAL jump back to instruction 4

; --- End ---
11. STR  X3, [X0, #10]  ; RAM[0x0A] = X3  (store final result)
12. BEQ  X0, X0, #-1    ; HALT  (infinite loop)
```

### Program Flow Diagram

```
        START
          │
          ▼
    ┌─────────────┐
    │ Init X6=5   │
    │ X1=0, X2=8  │
    │ X3=0        │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     X2==0
    │  X2 == 0?   │──────────────► STORE X3 → RAM[0x0A]
    └──────┬──────┘                      │
           │ X2 ≠ 0                      ▼
           ▼                           HALT
    ┌─────────────┐
    │ Load X4 =   │
    │  RAM[X1]    │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     X4==5
    │  X4 == 5?   │──────────────► SKIP
    └──────┬──────┘                  │
           │ X4 ≠ 5                  │
           ▼                         │
    ┌─────────────┐                  │
    │    X3++     │                  │
    └──────┬──────┘                  │
           │◄────────────────────────┘
           ▼
    ┌─────────────┐
    │ X1++, X2--  │
    └──────┬──────┘
           │
           └──────────────────────────► (back to loop check)
```

---

## Machine Code

### Hex Encoding Table

| # | Assembly Instruction | Binary (16-bit) | Hex |
|:---:|---|:---:|:---:|
| 0  | `ADDI X6, X0, #5`   | `0000 1110 0000 0101` | `0E05` |
| 1  | `ADDI X1, X0, #0`   | `0000 1001 0000 0000` | `0900` |
| 2  | `ADDI X2, X0, #8`   | `0000 1010 0000 1000` | `0A08` |
| 3  | `ADDI X3, X0, #0`   | `0000 1011 0000 0000` | `0B00` |
| 4  | `BEQ  X2, X0, #6`   | `1000 0010 0000 0110` | `8206` |
| 5  | `LDR  X4, [X1, #0]` | `0010 1100 0010 0000` | `2C20` |
| 6  | `BEQ  X4, X6, #1`   | `1000 0110 1000 0001` | `8681` |
| 7  | `ADDI X3, X3, #1`   | `0000 1011 0110 0001` | `0B61` |
| 8  | `ADDI X1, X1, #1`   | `0000 1001 0010 0001` | `0921` |
| 9  | `SUBI X2, X2, #1`   | `0010 0010 0100 0001` | `2241` |
| 10 | `BEQ  X0, X0, #-7`  | `1000 0000 0001 1001` | `8019` |
| 11 | `STR  X3, [X0, #10]`| `0100 1011 0000 1010` | `4B0A` |
| 12 | `BEQ  X0, X0, #-1`  | `1000 0000 0001 1111` | `801F` |

### ROM Contents (ready to paste into Logisim)

```
0E05 0900 0A08 0B00 8206 2C20 8681 0B61 0921 2241 8019 4B0A 801F
```

> **How to load:** Double-click the ROM component in Logisim → paste the hex values above.

---

## Simulation Results

### Test Configuration

| Property | Value |
|---|---|
| Array contents | `[6, 3, 5, 4, 5, 8, 5, 9]` |
| Array location in RAM | Addresses `0x00` – `0x07` |
| Result stored at | Address `0x0A` |
| Expected result | **5** (elements: 6, 3, 4, 8, 9 are ≠ 5) |

### Execution Trace

| Step | PC | Instruction | Key Register Change |
|:---:|:---:|---|---|
| Init | 0x00 | ADDI X6, X0, #5 | X6 = 5 |
| Init | 0x01 | ADDI X1, X0, #0 | X1 = 0 |
| Init | 0x02 | ADDI X2, X0, #8 | X2 = 8 |
| Init | 0x03 | ADDI X3, X0, #0 | X3 = 0 |
| Loop | 0x04 | BEQ X2, X0, #6 | X2≠0 → no branch |
| Loop | 0x05 | LDR X4,[X1,#0] | X4 = 6 |
| Loop | 0x06 | BEQ X4, X6, #1 | 6≠5 → no branch |
| Loop | 0x07 | ADDI X3, X3, #1 | **X3 = 1** |
| ... | ... | *(8 iterations)* | ... |
| End  | 0x0B | STR X3,[X0,#10] | **RAM[0x0A] = 5** |
| Halt | 0x0C | BEQ X0, X0, #-1 | PC stays at 0x0C |

### ✅ Final Result

```
RAM[0x0A] = 0x0005  ✓
```

The processor correctly identified **5 elements** not equal to 5.

---
Simulation Result

<img width="532" height="178" alt="image" src="https://github.com/user-attachments/assets/1169cc67-e2c2-4bc0-91bb-c4887d1f0704" />

---

## 📁 Repository Structure

```
16bit-processor-project/
│
├── README.md                   ← You are here
│
├── src/
│   └── processor.circ             ← Logisim circuit file (main)
│
├── docs/
│   └── report.pdf                 ← Full project report (3–4 pages)
└── 
```

---

## How to Run

### Prerequisites

- [Logisim generic 2.7.1]
- Java 11 or higher

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/Eqbal-eo/16bit-processor-project.git
cd 16bit-processor-project

# 2. Open in Logisim
#    File → Open → select src/processor.circ
```

Then inside Logisim:

1. **Load the array** into RAM: double-click the RAM component → enter `[6, 3, 5, 4, 5, 8, 5, 9]` starting at address `0x00`
2. **Verify ROM** contains the hex program: `0E05 0900 0A08 0B00 8206 2C20 8681 0B61 0921 2241 8019 4B0A 801F`
3. **Run simulation**: `Simulate → Enable Clock` or press `T` to step manually
4. **Check result**: after halt at PC=`0x0C`, inspect RAM address `0x0A` → should show `0x0005`

---

## Author

<div align="center">

| | |
|:---:|:---|
| **Name** | Eqbal |
| **GitHub** | [@Eqbal-eo](https://github.com/Eqbal-eo) |
| **Email** | [eng.mhdeqbal@gmail.com](mailto:eng.mhdeqbal@gmail.com) |

</div>

---

<div align="center">

*Faith in the heart, logic in the circuit*

</div>
