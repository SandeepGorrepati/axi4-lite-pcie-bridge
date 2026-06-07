#!/usr/bin/env python3
"""Compile and run the AXI4-Lite to PCIe-style bridge regression."""

from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
PROOF = ROOT / "proof"
SIM_OUT = BUILD / "axi_pcie_bridge.out"
LOG = PROOF / "axi_regression.log"

RTL = [
    "rtl/cfg_regs.sv",
    "rtl/packet_builder.sv",
    "rtl/sync_fifo.sv",
    "rtl/pcie_tx_engine.sv",
    "rtl/pcie_rx_engine.sv",
    "rtl/completion_manager.sv",
    "rtl/axi_pcie_bridge_top.sv",
]

TB = [
    "tb/axi_protocol_checker.sv",
    "tb/axi_coverage_tracker.sv",
    "tb/tb_axi_pcie_bridge.sv",
]


def run(cmd):
    print("+ " + " ".join(cmd))
    return subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True)


def main():
    BUILD.mkdir(exist_ok=True)
    PROOF.mkdir(exist_ok=True)

    compile_cmd = ["iverilog", "-g2012", "-Wall", "-s", "tb_axi_pcie_bridge", "-o", str(SIM_OUT)] + RTL + TB
    compile_result = run(compile_cmd)
    if compile_result.returncode != 0:
        print(compile_result.stdout)
        print(compile_result.stderr, file=sys.stderr)
        return compile_result.returncode

    sim_result = run(["vvp", str(SIM_OUT)])
    LOG.write_text(sim_result.stdout + sim_result.stderr)
    print(sim_result.stdout)
    if sim_result.stderr:
        print(sim_result.stderr, file=sys.stderr)

    log_text = LOG.read_text()
    required = [
        "AXI TESTBENCH SUMMARY",
        "AXI PROTOCOL CHECK SUMMARY",
        "AXI FUNCTIONAL COVERAGE SUMMARY",
        "FAIL=0",
    ]

    missing = [item for item in required if item not in log_text]
    if sim_result.returncode != 0 or missing:
        print(f"REGRESSION FAILED: missing markers: {missing}", file=sys.stderr)
        return 1

    print(f"REGRESSION PASSED: log saved to {LOG}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
