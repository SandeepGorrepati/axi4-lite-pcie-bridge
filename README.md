# AXI4-Lite to PCIe-Style Transaction Bridge in Verilog

## Overview
This project implements a simplified AXI4-Lite to PCIe-style transaction bridge in Verilog/SystemVerilog. It converts AXI4-Lite memory-mapped read/write requests into internal packetized PCIe-style transactions and returns completion responses back to the AXI interface.

The design models transaction-layer behavior including AXI valid/ready handshakes, packet construction, FIFO buffering, transmit/receive flow, completion handling, and response generation.

---

## Architecture

```text
AXI4-Lite Slave -> Packet Builder -> FIFO -> TX Engine -> RX Engine -> Completion Manager -> AXI Response
```

### Key Components
- **AXI4-Lite Slave Interface:** Accepts read/write address, data, and response handshakes
- **Packet Builder:** Converts AXI transactions into simplified PCIe-style packet fields
- **FIFO Buffer:** Decouples AXI request acceptance from transmit flow
- **TX Engine:** Drives packetized requests based on transmit readiness
- **RX Engine:** Models memory-side behavior and completion packet generation
- **Completion Manager:** Converts completion packets back into AXI read/write responses
- **Config Registers:** Provides address range control and bridge enable behavior

---

## Packet Format

| Field | Bits |
|---|---:|
| Tag | [75:72] |
| Byte Enable | [71:68] |
| Type | [67:64] |
| Address | [63:32] |
| Data | [31:0] |

### Packet Types
- `4'h1` -> Write Request
- `4'h2` -> Read Request
- `4'h8` -> Completion without data
- `4'h9` -> Completion with data
- `4'hF` -> Error

---

## Verification Environment

The testbench verifies AXI4-Lite protocol behavior, packetized transaction flow, read/write response sequencing, and data integrity using directed and randomized scenarios.

```text
AXI Tasks -> DUT -> Protocol Checker
              |-> Coverage Tracker
              |-> Testbench PASS/FAIL Checks
```

### Verification Components
- `tb/tb_axi_pcie_bridge.sv`: directed and randomized AXI transaction testbench
- `tb/axi_protocol_checker.sv`: Icarus-friendly SystemVerilog protocol checker
- `tb/axi_coverage_tracker.sv`: functional coverage tracker for operation/address/response bins
- `scripts/run_regression.py`: Python regression runner that compiles, runs, checks markers, and saves logs
- `TESTPLAN.md`: scenario, protocol-check, coverage, and pass-criteria documentation

---

## Test Scenarios

- Empty address read returns `0x00000000`
- Directed write/readback at `0x10`
- Directed write/readback at `0x20`
- Overwrite behavior at `0x20`, verifying latest data is returned
- Mid-range address write/readback
- High-range address write/readback
- Randomized aligned address/data write-readback scenarios

---

## Protocol Checks

Implemented in `tb/axi_protocol_checker.sv`:

- Known-value checks for AXI address, data, and strobe signals during valid phases
- Write response sequencing: `BVALID` should follow accepted write transaction
- Read response sequencing: `RVALID` should follow accepted read transaction
- No spurious write/read response without pending transaction
- `BRESP` and `RRESP` should report OKAY response status

---

## Functional Coverage Tracking

Implemented in `tb/axi_coverage_tracker.sv`:

- Operation bins: accepted write/read transactions
- Address range bins: low, mid, and high address ranges
- Response bins: observed write/read responses
- Cross-style bins: write/read distribution across address ranges

---

## Latest Regression Result

A passing run includes:

```text
AXI PROTOCOL CHECK SUMMARY
WRITES=11 READS=12 BRESP=11 RRESP=12 PASS=46 FAIL=0

AXI FUNCTIONAL COVERAGE SUMMARY
Operation bins       : writes=11 reads=12
Address range bins   : low=11 mid=2 high=10
Response bins        : bresp_seen=11 rresp_seen=12
Cross op x addr bins : W_LOW=5 W_MID=1 W_HIGH=5 R_LOW=6 R_MID=1 R_HIGH=5
```

---

## Waveform Proof

### Write Transaction Flow
![Write Flow](screenshots/axi_pcie_write_flow.png)

### Read Transaction Flow
![Read Flow](screenshots/axi_pcie_read_transaction_flow.png)

### Write -> Readback Verification
![Readback](screenshots/axi_pcie_write_readback_verification.png)

---

## How to Run

### Recommended regression command

```bash
python3 scripts/run_regression.py
```

### Manual command

```bash
make clean
make run
```

Open waveform:

```bash
gtkwave build/axi_pcie_bridge.vcd
```
