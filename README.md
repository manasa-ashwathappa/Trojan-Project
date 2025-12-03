# Hardware Trojan Automation Using Large Language Models

**Authors:** Manasa Ashwathappa (ma8686) | Bhanu Dileep Reddy Maryada

## Overview

This repository demonstrates automated hardware Trojan insertion using large language models (LLMs) across two assignments:

1. **OpenTitan UART Core** - Five unique Trojans generated using GPT-4o-mini
2. **AES & Wishbone-UART** - CSAW AHA challenge tasks

Full documentation: `OpenTitan Report.pdf`

---

## OpenTitan UART Trojans

Automated generation of five hardware Trojans using GPT-4o-mini targeting the OpenTitan UART Core.

### Repository Structure

```
OpenTitan/
├── opentitan_trojans/
│   ├── trojan_T1/
│   │   ├── rtl/uart_core.sv
│   │   ├── tb/uart_trojan_T1_tb.sv
│   │   └── ai/
│   │       ├── conversation_log.txt
│   │       └── trojan_description.txt
│   ├── trojan_T2/
│   ├── trojan_T3/
│   ├── trojan_T4/
│   └── trojan_T5/
└── debug_T[1-5]_raw_response.txt
```

---

## Description of OpenTitan Trojans

| Trojan | Type | Trigger | Payload |
|--------|------|---------|---------|
| **T1** | Backdoor | 4-byte sequence `0xDEADBEEF` | Activates hidden debug mode |
| **T2** | Info Leakage | Internal secret bits | Timing variations on TX path |
| **T3** | Denial of Service | Byte `0xFF` received | UART becomes unresponsive |
| **T4** | Data Corruption | Every 16th byte | Flips MSB of received byte |
| **T5** | Privilege Escalation | Odd-parity mode | Bypasses parity checking |

Detailed analysis in `OpenTitan Report.pdf`

---

## AES & Wishbone-UART Tasks

CSAW AHA challenge implementations with LLM-generated hardware Trojans.

### Repository Structure

```
AES/
├── content/aes/
│   ├── aes_128.v
│   ├── table.v
│   ├── round.v
│   └── gpt-4.1-mini/aes_128/
│       ├── aes_128_HT1_*.v
│       ├── aes_128_HT2_*.v
│       ├── aes_128_HT3_*.v
│       └── aes_128_HT4_*.v
├── aes.zip
└── sim.vvp
```

### Tasks

| Task | Description |
|------|-------------|
| **HT1** | AES Key Leakage - Leak key material while maintaining normal behavior |
| **HT2** | AES DoS - Halt after 862 encryptions |
| **HT3** | Wishbone-UART DoS - Freeze on sequence `0x10, 0xa4, 0x98, 0xbd` |
| **HT4** | UART Modification - Bit-reverse writes after three `0xaf` bytes |

---

## Running Simulations

### OpenTitan

```bash
cd OpenTitan/opentitan_trojans/trojan_T1/tb
iverilog -g2012 -o sim.out ../rtl/*.sv uart_trojan_T1_tb.sv
vvp sim.out
gtkwave dump.vcd
```

### AES

```bash
cd AES/content/aes
iverilog -g2012 -o aes_sim.out aes_128.v round.v table.v
vvp aes_sim.out
```
