SIM_OUT = build/axi_pcie_bridge.out
VCD = build/axi_pcie_bridge.vcd
LOG = proof/axi_regression.log

RTL = rtl/cfg_regs.sv \
      rtl/packet_builder.sv \
      rtl/sync_fifo.sv \
      rtl/pcie_tx_engine.sv \
      rtl/pcie_rx_engine.sv \
      rtl/completion_manager.sv \
      rtl/axi_pcie_bridge_top.sv

TB = tb/axi_protocol_checker.sv \
     tb/axi_coverage_tracker.sv \
     tb/tb_axi_pcie_bridge.sv

build:
	mkdir -p build proof

compile: build
	iverilog -g2012 -Wall -s tb_axi_pcie_bridge -o $(SIM_OUT) $(RTL) $(TB)

run: compile
	vvp $(SIM_OUT) | tee $(LOG)

regress:
	python3 scripts/run_regression.py

wave:
	gtkwave $(VCD)

clean:
	rm -rf build proof
