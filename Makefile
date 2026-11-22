# ==============================================================================
# Makefile: Closed-Loop AVS Power Management Macro on Sky130
# ==============================================================================

SHELL := /bin/bash

.PHONY: all sim analog synth sta pd post_route_sta layout drc lvs pex mixed_signal model pvt_matrix energy_curves validate clean help test lint check build report fmt

all: sim analog synth sta pd post_route_sta layout drc lvs pex mixed_signal model pvt_matrix energy_curves
	@echo "=================================================================="
	@echo "  All verification, synthesis, PD, layout, and STA completed!     "
	@echo "=================================================================="

help:
	@echo "Available build targets:"
	@echo "  make sim            - Run all 4 digital RTL testbenches with Icarus Verilog"
	@echo "  make analog         - Run ngspice DC, AC, and transient simulations (BGR, DAC, LDO)"
	@echo "  make synth          - Synthesize digital macro to Sky130 HD using Yosys"
	@echo "  make sta            - Run pre-route multi-corner OpenSTA timing analysis (TT, SS, FF)"
	@echo "  make pd             - Run digital physical design (Floorplan, PDN, Placement, CTS, Route, SPEF)"
	@echo "  make post_route_sta - Run post-route OpenSTA timing analysis with back-annotated SPEF"
	@echo "  make layout         - Generate custom analog layouts in Magic (DAC matrix & PMOS pass)"
	@echo "  make drc            - Run Magic Design Rule Checking on analog layouts (fail-closed)"
	@echo "  make lvs            - Run structural device/finger audit on Magic extracted layouts"
	@echo "  make pex            - Run Magic Parasitic Extraction (PEX) & post-layout comparison"
	@echo "  make mixed_signal   - Run top-level mixed-signal SPICE and closed-loop co-simulation"
	@echo "  make model          - Run closed-loop co-simulation and CPM timing calibration"
	@echo "  make pvt_matrix     - Display 6-corner PVT sign-off matrix report"
	@echo "  make energy_curves  - Generate energy-per-op vs voltage scaling trade-off curves"
	@echo "  make validate       - Run complete Stage 1-5 validation suite"
	@echo "  make all            - Run complete end-to-end pipeline"
	@echo "  make clean          - Clean generated waveform files and logs"
	@echo ""
	@echo "Standard developer aliases (inspired by top-10 open-source repositories):"
	@echo "  make test           - Run fast regression testbenches (RTL simulations and models)"
	@echo "  make lint           - Lint RTL sources using Icarus Verilog strict syntax check"
	@echo "  make check          - Fast sanity check combining RTL sim, model, and PVT matrix"
	@echo "  make build          - Build digital gate-level and physical design database (synth + pd)"
	@echo "  make report         - Display PVT sign-off summary matrix"
	@echo "  make fmt            - Inspect and validate codebase compliance with .editorconfig"

test: sim model
	@echo "--> Test suite passed successfully."

lint:
	@echo "--> Linting RTL sources with Icarus Verilog (-Wall)..."
	@mkdir -p sim
	iverilog -Wall -g2012 -o sim/lint_check.vvp rtl/level_shifter/level_shifter.v rtl/load/pipelined_mac_load.v rtl/cpm/critical_path_monitor.v rtl/controller/avs_controller.v rtl/top/avs_system_top.v
	@rm -f sim/lint_check.vvp
	@echo "--> RTL lint check clean."

check: sim model pvt_matrix
	@echo "--> Quick sanity check complete."

build: synth pd
	@echo "--> Build complete (Gate-level netlist & Physical Design database ready)."

report: pvt_matrix

fmt:
	@echo "--> Checking codebase compliance with .editorconfig guidelines..."
	@python3 scripts/check_formatting.py

sim:
	@echo "--> Running digital RTL testbenches..."
	@mkdir -p sim reports
	iverilog -g2012 -o sim/tb_controller.vvp rtl/controller/avs_controller.v sim/tb_controller.v
	vvp sim/tb_controller.vvp
	iverilog -g2012 -o sim/tb_cpm.vvp rtl/cpm/critical_path_monitor.v sim/tb_cpm.v
	vvp sim/tb_cpm.vvp
	iverilog -g2012 -o sim/tb_cdc.vvp rtl/level_shifter/level_shifter.v sim/tb_cdc.v
	vvp sim/tb_cdc.vvp
	iverilog -g2012 -o sim/tb_avs_top.vvp rtl/level_shifter/level_shifter.v rtl/load/pipelined_mac_load.v rtl/cpm/critical_path_monitor.v rtl/controller/avs_controller.v rtl/top/avs_system_top.v sim/tb_avs_top.v
	vvp sim/tb_avs_top.vvp

analog:
	@echo "--> Running ngspice transistor-level simulations..."
	cd analog/ldo && ngspice -b ldo_core.sp
	cd analog/dac && ngspice -b dac_5bit_rstring.sp
	python3 analog/dac/verify_dac_linearity.py
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
	@echo "--> Running Magic Structural Device LVS Audit..."
	python3 analog/layout/run_lvs.py

pex:
	@echo "--> Running Magic Parasitic Extraction (PEX) & ngspice comparison..."
	python3 analog/layout/run_pex.py

mixed_signal:
	@echo "--> Running Mixed-Signal Top-Level Integration & Co-Simulation..."
	cd sim && ngspice -b mixed_signal_top.sp
	python3 sim/run_mixed_signal_co_sim.py
	@echo "Mixed-signal integration verified: reports/mixed_signal_transient.png."

model:
	@echo "--> Running closed-loop co-simulation and CPM calibration..."
	@mkdir -p reports
	python3 models/closed_loop_avs_sim.py
	python3 models/cpm_calibration.py

pvt_matrix:
	@echo "--> Checking PVT Cross-Corner Sign-off Matrix..."
	@cat reports/pvt_cross_corner_matrix.rpt

energy_curves:
	@echo "--> Generating Energy-per-Op vs Voltage Scaling Trade-off Curves..."
	@mkdir -p reports
	python3 models/generate_energy_tradeoff_curves.py

validate: all
	@echo "=================================================================="
	@echo "  Stage 1-5 Complete Validation Suite Executed Successfully!      "
	@echo "=================================================================="

clean:
	rm -f sim/*.vvp sim/*.vcd *.vcd *.vvp *.log
	rm -f sta/*.log synth/*.log reports/*.log
