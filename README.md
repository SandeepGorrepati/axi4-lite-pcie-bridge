# AXI4-Lite to educational packet bridge

![Bridge regression](https://github.com/SandeepGorrepati/axi4-lite-pcie-bridge/actions/workflows/regression.yml/badge.svg)

A SystemVerilog transaction bridge connecting AXI4-Lite to a FIFO-buffered, 76-bit internal packet interface and an on-chip memory endpoint. This is a PCIe-style educational packet format, not real PCIe TLP/link/PHY implementation, Gen3/Gen4 support, or PCIe compliance.

## Implemented behavior

- Independently capture AW and W in either order; complete one write only after both arrive.
- Serialize read/write ownership through request, completion, and AXI response acceptance.
- Preserve B/R response VALID and payload while the master stalls.
- Consume a transmitted packet exactly when VALID and external READY are both asserted.
- Route error completions to B or R using the outstanding request type.
- Apply all four byte enables to a 256-word memory behind a default 1 KiB window.
- Return OKAY for valid addresses and SLVERR with a diagnostic read value for invalid accesses.
- Reset cancels a partial request and clears the endpoint memory.

A partial write owns the input until the missing channel arrives. Reads are not accepted alongside an active/partial write. There is one complete transaction outstanding; the FIFO is not a claim of multi-outstanding AXI throughput. Tags are educational fields, not an independently validated PCIe completion-tag mechanism.

## Reproduce with free tools

Install Python 3 and Icarus Verilog; from the root:

```bash
python3 scripts/run_regression.py
python3 scripts/gen_vectors.py
iverilog -g2012 -s tb_bridge_protocol -o build/stress rtl/*.sv tb/tb_bridge_protocol.sv
vvp build/stress
```

GitHub Actions runs both tests and retains logs.

## Verified tests

| Layer | Evidence |
|---|---|
| Legacy directed/random test | 12 data checks; protocol summary 11 writes, 12 reads, zero failures |
| Independent Python byte-memory oracle | 1,075 write/read pairs with data/response checks |
| Channel timing | Simultaneous, AW-first, W-first; randomized delays |
| Byte strobes | All 16 masks plus partial/random writes and full final readback |
| Backpressure | B/R response holds plus periodic stalls of packet TX READY |
| Errors | Invalid-address read/write status, valid-memory alias protection |
| Reset | Cancel partial AW-only write; check no orphan response and recovery |
| Packet accounting | Exactly 2,152 packet transfers/completions, including post-reset recovery |

The legacy procedural checker and coverage tracker assume simultaneous AW/W and sample response cycles; they are used only by the legacy directed test. The separate oracle stress test checks independent channel behavior and response holds. No aggregate coverage percentage is claimed.

## Bugs found and fixed

The old top level advertised independent READY signals but only processed writes when AWVALID and WVALID were simultaneously high. It returned to accepting requests before stalled responses were consumed. The loopback receiver also consumed TX VALID while external TX READY was low, potentially repeating completions, and generic error completions were always routed as write responses.

The upgraded design stores independent channel handshakes, holds transaction ownership through AXI response acceptance, gates packet reception by the actual transfer condition, and uses the outstanding request type to route errors. The stress test checks data and exact packet/completion counts.

## Limits

There is no PCIe PHY, LTSSM, real TLP header, CRC, credit/replay mechanism, enumeration, DMA, interrupt, multi-clock CDC, or hardware validation. The endpoint is an educational memory model. Default aligned 32-bit accesses and the four-entry FIFO are the tested configuration. This is a bus/packet-verification project, not a deployable PCIe controller.

See [upgrade validation](proof/UPGRADE_VALIDATION.md).
