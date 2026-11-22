# ==============================================================================
# Makefile: Closed-Loop AVS Power Management Macro on Sky130
# ==============================================================================

SHELL := /bin/bash

.PHONY: all sim analog synth sta pd post_route_sta layout drc lvs pex mixed_signal model clean help

all: sim analog synth sta pd post_route_sta layout drc lvs pex mixed_signal model
	@echo "=================================================================="
	@echo "  All verification, synthesis, PD, layout, and STA completed!     "
	@echo "=================================================================="

help:
	@echo "Available build targets:"
	@echo "  make sim            - Run digital functional testbenches with Icarus Verilog"
	@echo "  make analog         - Run ngspice DC, AC, and transient simulations (BGR, DAC, LDO)"
	@echo "  make synth          - Synthesize digital macro to Sky130 HD using Yosys"
	@echo "  make sta            - Run pre-route multi-corner OpenSTA timing analysis (TT, SS, FF)"
	@echo "  make pd             - Run digital physical design (Floorplan, PDN, Placement, CTS, Route, SPEF)"
	@echo "  make post_route_sta - Run post-route OpenSTA timing analysis with back-annotated SPEF"
	@echo "  make layout         - Generate custom analog layouts in Magic (DAC matrix & PMOS pass)"
	@echo "  make drc            - Run Magic Design Rule Checking on analog layouts"
	@echo "  make lvs            - Run Netgen LVS comparing layout against schematic"
	@echo "  make pex            - Run Parasitic Extraction (PEX) & post-layout comparison"
	@echo "  make mixed_signal   - Run top-level mixed-signal SPICE and closed-loop co-simulation"
	@echo "  make model          - Run closed-loop co-simulation and generate energy plots"
	@echo "  make all            - Run complete end-to-end pipeline"
	@echo "  make clean          - Clean generated waveform files and logs"

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

pd:
	@echo "--> Running Digital Physical Design flow..."
	@mkdir -p pd/results reports
	python3 pd/scripts/floorplan_and_pdn.py
	python3 pd/scripts/placement_and_cts.py
	python3 pd/scripts/route_and_extract_spef.py
	@echo "PD flow complete: Floorplan DEF, Placed DEF, and SPEF extracted."

post_route_sta:
	@echo "--> Running Post-Route OpenSTA Sign-off with SPEF Back-Annotation..."
	export CORNER=TT && sta pd/scripts/run_post_route_sta.tcl > reports/post_route_sta_tt.log 2>&1
	export CORNER=SS && sta pd/scripts/run_post_route_sta.tcl > reports/post_route_sta_ss.log 2>&1
	export CORNER=FF && sta pd/scripts/run_post_route_sta.tcl > reports/post_route_sta_ff.log 2>&1
	@echo "Post-route STA sign-off complete across corners (TT, SS, FF)."

layout:
	@echo "--> Generating custom analog layouts in Magic..."
	@mkdir -p analog/layout
	python3 analog/layout/generate_dac_layout.py
	python3 analog/layout/generate_pmos_pass_layout.py
	@echo "Analog layouts generated: dac_5bit_array.mag, pmos_pass_2000u.mag."

drc:
	@echo "--> Running Magic Design Rule Check (DRC)..."
	python3 analog/layout/run_drc.py

lvs:
	@echo "--> Running Netgen Layout Versus Schematic (LVS)..."
	python3 analog/layout/run_lvs.py

pex:
	@echo "--> Running Parasitic Extraction (PEX) & comparison..."
	python3 analog/layout/run_pex.py

mixed_signal:
	@echo "--> Running Mixed-Signal Top-Level Integration & Co-Simulation..."
	cd sim && ngspice -b mixed_signal_top.sp
	python3 sim/run_mixed_signal_co_sim.py
	@echo "Mixed-signal integration verified: reports/mixed_signal_transient.png."

model:
	@echo "--> Running closed-loop co-simulation..."
	@mkdir -p reports
	python3 models/closed_loop_avs_sim.py

clean:
	rm -f sim/*.vvp *.vcd *.data *.log
	rm -f analog/*/*.data analog/*/*.log
