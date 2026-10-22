# Bridge verification traceability

| Feature | Test | Check |
|---|---|---|
| Legacy valid read/write | run_regression.py | Data checks, legacy protocol summary |
| Independent AW/W | tb_bridge_protocol + gen_vectors.py | Completion and byte-memory readback |
| All strobes | 16-mask directed sweep | Independent Python byte updates |
| Response backpressure | Hold BREADY/RREADY | VALID, status, and data remain stable |
| Packet backpressure | Periodic TX READY stalls | Exact packet/completion accounting and readback |
| Invalid addresses | High addresses and alias probes | SLVERR, diagnostic read data, unchanged valid words |
| Reset partial request | Accept AW then reset | No orphan B/R, normal transaction recovery |

Run counts and source links are in proof/UPGRADE_VALIDATION.md. The old checker/coverage tracker is scoped to the legacy simultaneous-channel test. The stress test is independent. No claim of full AXI or PCIe compliance, all FIFO parameter combinations, or exhaustive correctness is made.
