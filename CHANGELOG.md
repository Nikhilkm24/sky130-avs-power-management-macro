# Changelog

All notable user-facing and engineering changes to the **Sky130 Adaptive Voltage Scaling (AVS) Power Management Macro** project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Transistor-level closed-loop mixed-signal SPICE transient co-simulation with dynamic digital load switching.
- Monte Carlo statistical mismatch characterization across 200 process runs for BGR temperature coefficient and LDO output offset.
- Thermal throttling controller interface for closed-loop thermal-voltage co-optimization.

---

## [1.3.0] - 2026-11-22

### Added
- **Critical Path Monitor (CPM) Redesign (P0)**:
  - Replaced direct tap pass-through wiring with real physical non-collapsible dual-inverter buffer stages (`cpm_delay_stage`) between every tap ($0 \dots 7$) with `keep` and `dont_touch` synthesis attributes.
  - Added dedicated unit testbench `sim/tb_cpm.v` verifying wavefront propagation, thermometer decoding, and emergency timing hazard assertion (8/8 tests passed).
  - Implemented alpha-power delay correlation model `models/cpm_calibration.py` calibrating replica path tracking against 16-bit MAC critical path ($R^2 = 0.8376$).
  - Generated sign-off calibration reports `reports/cpm_calibration.rpt` and `reports/cpm_pvt_characterization.rpt`.
- **Clock Domain Crossing (CDC) Gray-Code Synchronizer**:
  - Implemented 4-bit binary-to-Gray encoder, 2-stage synchronizer, and Gray-to-binary decoder (`cdc_gray_synchronizer`) in `rtl/level_shifter/level_shifter.v`.
  - Eliminated multi-bit sampling skew on `cpm_margin_code` crossing from `clk_core` (75.0 MHz) to `clk_ctrl` (12.5 MHz).
  - Added dedicated CDC unit testbench `sim/tb_cdc.v` (12/12 tests passed).
- **Physical Layout-Derived Parasitic Extraction (P0)**:
  - Overhauled `analog/layout/run_pex.py` to run native Magic batch parasitic extraction (`ext2spice cthresh 0.001`).
  - Extracted real lumped parasitic networks: 906 capacitors ($1405.83\text{ fF}$) for the 64-finger PMOS pass device and 415 capacitors ($32.01\text{ fF}$) for the 32-tap DAC array.
  - Executed post-layout ngspice transient simulation and generated comparative report `reports/analog_pex_comparison.rpt`.
- **Verification Claim & Metric Audit Matrix**:
  - Authored comprehensive ground-truth matrix `reports/VERIFICATION_CLAIM_AUDIT.md` categorizing all subsystem claims into `[TOOL-VERIFIED]`, `[SIMPLIFIED-MODEL]`, `[MODELED-EXTRAPOLATED]`, `[INCOMPLETE-WIP]`, and `[CORRECTED-DEFECT]`.
- **Automated Codebase Formatting Validation**:
  - Added `.editorconfig` audit script `scripts/check_formatting.py` and normalizer `scripts/fix_formatting.py`.
  - Normalized all 64 repository files to clean LF line endings and trimmed trailing whitespace.
  - Integrated formatting audit into `make fmt` and GitHub Actions CI.

### Changed
- **Fail-Closed DRC Automation (P0)**: Overhauled `analog/layout/run_drc.py` to assert subprocess return codes and regex match results, failing closed on unexpected output (verified 0 DRC violations in Magic 8.3).
- **Honest Layout vs. Schematic (LVS) Audit (P0)**: Replaced mock Netgen reporting in `analog/layout/run_lvs.py` with genuine Magic SPICE netlist extraction and device auditing (64 PMOS fingers, 32 DAC taps), declaring structural layout validation until OpenCircuitDesign Netgen is integrated.
- **Analog SPICE Model Scoping (P1)**: Explicitly labeled all transistor-level netlists (`analog/bgr/`, `analog/ldo/`, `analog/dac/`) as simplified Level-1 exploratory circuit models rather than foundry BSIM sign-off models.
- **Timing & FSM Alignment**: Unified system operating clock to 75.0 MHz across SDC constraints, RTL headers, and documentation; documented 6 FSM states in `rtl/controller/avs_controller.v` and synchronous emergency timing response ($\le 80\text{ ns}$).
- **CI/CD Pipeline Expansion**: Upgraded `.github/workflows/ci.yml` to execute all 4 unit testbenches (`tb_cpm`, `tb_cdc`, `tb_controller`, `tb_avs_top`), both analytical models (`closed_loop_avs_sim.py`, `cpm_calibration.py`), and the `.editorconfig` formatting audit on Ubuntu CI runners.

---

## [1.2.0] - 2026-11-22

### Added
- **Repository Architecture Alignment**: Implemented top-10 open-source engineering standards based on the *GitHub Repository Engineering Handbook* (Prometheus, Docker Compose, Terraform, Kubernetes).
- **Collaboration Infrastructure**: Added formal repository guidelines, templates, and specifications:
  - `CONTRIBUTING.md`: Development guidelines, branch workflows, coding conventions, and verification gates.
  - `BUILDING.md`: Complete EDA toolchain setup guide covering WSL2, Icarus Verilog, Yosys, OpenSTA, Magic, Netgen, and ngspice.
  - `.editorconfig`: Multi-editor whitespace, line ending, and indentation rules.
  - `.github/ISSUE_TEMPLATE/`: Formal engineering templates for bug reports and feature requests.
  - `.github/PULL_REQUEST_TEMPLATE.md`: Comprehensive PR checklist and verification sign-off form.
  - `docs/index.md`: Master documentation hub with unified technical navigation.
  - `docs/verification_plan.md`: End-to-end hardware verification plan detailing coverage matrices across RTL, analog, STA, PD, and closed-loop co-sim.
- **Automated CI/CD Expansion**: Expanded GitHub Actions workflow (`.github/workflows/ci.yml`) to include RTL linting, integrated top-level system testbench execution, and automated PVT matrix validation.
- **Makefile Developer Aliases**: Added top-10 standard aliases (`fmt`, `lint`, `test`, `build`, `report`, `check`) while retaining core sign-off targets.

### Changed
- Refactored `README.md` to include quick-navigation links, complete directory layout, and contribution instructions.
- Adjusted Makefile clean target to safeguard committed simulation sign-off data.

---

## [1.1.0] - 2026-11-22

### Added
- **Physical Design Sign-off**: Integrated post-route OpenSTA timing back-annotation using extracted SPEF parasitics.
- **Cross-Corner PVT Sign-off Matrix**: Generated automated 6-corner PVT sign-off summary report (`reports/pvt_cross_corner_matrix.rpt`).
- **Antigravity Engineering Rules**: Added `AGENTS.md` and `.agents/rules/engineering-standards.md`.

### Changed
- **Technical Tone Refinement**: Completely refactored `README.md` and documentation suite to remove promotional interview language and replace it with rigorous engineering analysis, clear scope boundaries, and explicit limitations.
- **License Clarification**: Upgraded `LICENSE` to specifically define proprietary educational and portfolio terms for the Sky130 AVS Macro Project.

### Fixed
- Corrected git committer and author identities across Windows and WSL environments (`Nikhil24` / `2023ec_nikhilkm_b@nie.ac.in`).

---

## [1.0.0] - 2026-11-22

### Added
- **Digital RTL Core**:
  - Synthesizable 5-state AVS controller FSM (`rtl/controller/avs_controller.v`) with hysteresis and rate limiting.
  - 8-stage Critical Path Monitor (CPM) delay line (`rtl/cpm/critical_path_monitor.v`) with phase detector and programmable calibration registers.
  - 16-bit pipelined MAC workload generator (`rtl/load/pipelined_mac_load.v`) for power characterization.
  - Dual-rail level shifters (`rtl/level_shifter/level_shifter.v`) for safe bidirectional level translation between 1.80V and 0.90V–1.50V domains.
  - Top-level integrated digital system (`rtl/top/avs_system_top.v`).
- **Analog & Power Electronics**:
  - Transistor-level 1.20 V bandgap reference schematic (`analog/bgr/bgr_1v2.sp`) with curvature compensation.
  - 5-bit resistor-string DAC schematic and Python verification harness (`analog/dac/`).
  - Low-Dropout (LDO) regulator (`analog/ldo/ldo_core.sp`) with folded-cascode error amplifier and PMOS pass transistor.
- **Physical Design & Layout**:
  - Open-source digital flow scripts (`pd/scripts/`) for floorplanning, PDN generation, placement, CTS, routing, and SPEF extraction.
  - Custom analog layout generators in Magic VLSI (`analog/layout/`) for 5-bit DAC array and PMOS pass transistor.
  - DRC, LVS, and PEX automation scripts (`analog/layout/`).
- **Static Timing Analysis**:
  - Multi-corner OpenSTA timing analysis scripts (`sta/scripts/`) targeting Sky130 HD library.
  - SPICE-to-STA critical path delay correlation analysis (`sta/spice_sta_correlate/`).
- **Behavioral Modeling & Energy Analytics**:
  - Closed-loop dynamic AVS system simulation model (`models/closed_loop_avs_sim.py`).
  - Energy-per-operation vs voltage trade-off curve generator (`models/generate_energy_tradeoff_curves.py`).
- **Documentation**:
  - Comprehensive technical specifications (`docs/SPECIFICATION.md`).
  - System architecture manual (`docs/SYSTEM_ARCHITECTURE.md`).
  - LDO datasheet summary (`docs/LDO_DATASHEET_SUMMARY.md`).
  - Technical roadmap (`docs/ROADMAP.md`).
