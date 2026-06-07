# AXI4-Lite to PCIe-Style Bridge Verification Test Plan

## Objective
Verify a simplified AXI4-Lite to PCIe-style transaction bridge using directed and randomized simulation scenarios, protocol checks, functional coverage tracking, regression logs, and waveform-backed debug proof.

## Design Under Test
The DUT accepts AXI4-Lite read/write transactions, packetizes them into a simplified PCIe-style request format, routes them through FIFO/TX/RX/completion logic, and returns AXI read/write responses.

## Verification Architecture
```text
AXI tasks -> DUT -> Protocol Checker
               |-> Coverage Tracker
               |-> Testbench PASS/FAIL checks
```

## DUT Interface
| Signal | Direction | Description |
|---|---|---|
| `s_axi_awaddr[31:0]` | input | AXI write address |
| `s_axi_awvalid` / `s_axi_awready` | input/output | AXI write address handshake |
| `s_axi_wdata[31:0]` | input | AXI write data |
| `s_axi_wstrb[3:0]` | input | AXI byte strobe |
| `s_axi_wvalid` / `s_axi_wready` | input/output | AXI write data handshake |
| `s_axi_bvalid` / `s_axi_bready` | output/input | AXI write response handshake |
| `s_axi_araddr[31:0]` | input | AXI read address |
| `s_axi_arvalid` / `s_axi_arready` | input/output | AXI read address handshake |
| `s_axi_rdata[31:0]` | output | AXI read data |
| `s_axi_rvalid` / `s_axi_rready` | output/input | AXI read response handshake |
| `pcie_tx_ready` | input | Simplified PCIe transmit readiness |

## Test Scenarios
| ID | Scenario | Expected Result |
|---|---|---|
| T1 | Read empty address | Returns `0x00000000` |
| T2 | Directed write/readback at `0x10` | Read data matches written data |
| T3 | Directed write/readback at `0x20` | Read data matches written data |
| T4 | Overwrite address `0x20` | Latest write data is returned |
| T5 | Mid-range address write/readback | Readback matches expected data |
| T6 | High-range address write/readback | Readback matches expected data |
| T7-T12 | Randomized aligned address/data write-readback | Readback matches randomized write data |

## Protocol Checks
Implemented in `tb/axi_protocol_checker.sv`:

| Check | Intent |
|---|---|
| Known-value checks | Address/data/strobe signals must not be X/Z when valid |
| Write response sequencing | `BVALID` should follow accepted write transaction |
| Read response sequencing | `RVALID` should follow accepted read transaction |
| No spurious response | `BVALID` / `RVALID` should not appear without pending transaction |
| OKAY response check | `BRESP` / `RRESP` should be `2'b00` |

## Functional Coverage Tracking
Implemented in `tb/axi_coverage_tracker.sv`:

| Coverage item | Intent |
|---|---|
| Operation bins | Count accepted write and read transactions |
| Address range bins | Count low/mid/high address activity |
| Response bins | Count observed write and read responses |
| Cross-style bins | Track write/read distribution across address ranges |

## Pass Criteria
- Testbench summary reports `FAIL=0`
- Protocol checker summary reports `FAIL=0`
- Functional coverage summary prints non-zero read/write activity
- Low, mid, and high address ranges are exercised
- Regression log is saved under `proof/axi_regression.log`

## Run Command
```bash
python3 scripts/run_regression.py
```

Manual option:
```bash
make clean
make run
```
