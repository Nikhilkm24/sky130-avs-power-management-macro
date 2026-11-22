# ==============================================================================
# Makefile: Closed-Loop AVS Power Management Macro on Sky130
# ==============================================================================

SHELL := /bin/bash

.PHONY: all sim analog synth sta model clean help

all: sim analog synth sta model
	@echo "=================================================================="
	@echo "  All verification, synthesis, and STA phases completed cleanly!  "
	@echo "=================================================================="

help:
	@echo "Available build targets:"
	@echo "  make sim     - Run digital functional testbenches with Icarus Verilog"
	@echo "  make analog  - Run ngspice DC, AC, and transient simulations (BGR, DAC, LDO)"
	@echo "  make synth   - Synthesize digital macro to Sky130 HD using Yosys"
	@echo "  make sta     - Run multi-corner OpenSTA timing analysis (TT, SS, FF)"
	@echo "  make model   - Run closed-loop co-simulation and generate energy plots"
	@echo "  make all     - Run complete end-to-end pipeline"
	@echo "  make clean   - Clean generated waveform files and logs"

sim:
	@echo "--> Running digital RTL testbenches..."
	@mkdir -p sim reports
	iverilog -g2012 -o sim/tb_controller.vvp rtl/controller/avs_controller.v sim/tb_controller.v
	vvp sim/tb_controller.vvp
	iverilog -g2012 -o sim/tb_avs_top.vvp rtl/level_shifter/level_shifter.v rtl/load/pipelined_mac_load.v rtl/cpm/critical_path_monitor.v rtl/controller/avs_controller.v rtl/top/avs_system_top.v sim/tb_avs_top.v
	vvp sim/tb_avs_top.vvp

analog:
	@echo "--> Running ngspice simulations..."
	cd analog/ldo && ngspice -b ldo_core.sp
	cd analog/dac && ngspice -b dac_5bit_rstring.sp
	cd analog/bgr && ngspice -b bgr_1v2.sp

synth:
	@echo "--> Synthesizing design using Yosys for Sky130 HD..."
	@mkdir -p synth
	yosys -s synth/synth_top.tcl > synth/yosys_synth.log 2>&1
	@tail -n 15 synth/yosys_synth.log

sta:
	@echo "--> Running OpenSTA multi-corner timing sign-off..."
	@mkdir -p sta/results
	export CORNER=TT && sta sta/scripts/run_sta_corners.tcl > sta/sta_tt.log 2>&1
	export CORNER=SS && sta sta/scripts/run_sta_corners.tcl > sta/sta_ss.log 2>&1
	export CORNER=FF && sta sta/scripts/run_sta_corners.tcl > sta/sta_ff.log 2>&1
	python3 sta/spice_sta_correlate/correlate_sta_spice.py
	@echo "OpenSTA reports generated: sta/sta_tt.log, sta/sta_ss.log, sta/sta_ff.log"

model:
	@echo "--> Running closed-loop co-simulation..."
	@mkdir -p reports
	python3 models/closed_loop_avs_sim.py

clean:
	rm -f sim/*.vvp *.vcd *.data *.log
	rm -f analog/*/*.data analog/*/*.log
