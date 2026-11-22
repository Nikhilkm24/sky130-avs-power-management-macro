# Verification Claim Audit & Technical Integrity Assessment
**Repository:** `sky130-avs-power-management-macro`  
**Milestone:** `v1.3.0` (Technical Integrity and Verification Recovery)  
**Date:** 2026-11-22  
**Author / Maintainer:** Nikhil KM (`Nikhil24` / `Nikhilkm24`)  

---

## 1. Executive Purpose

This document provides a line-by-line audit of all engineering claims, verification scripts, simulation models, and sign-off reports within the `sky130-avs-power-management-macro` repository. 

To ensure complete technical defensibility for semiconductor peer review and academic evaluation, every claim is formally classified under one of five strict categories:

1. **[TOOL-VERIFIED]**: Verified by direct, automated execution of an open-source EDA tool (Icarus Verilog, Yosys, OpenSTA, Magic) with zero errors and real log outputs.
2. **[SIMPLIFIED-MODEL]**: Verified using simplified behavioral or Level-1 SPICE models for circuit experimentation; NOT representative of foundry-calibrated BSIM silicon models.
3. **[MODELED-EXTRAPOLATED]**: Calculated via mathematical, behavioral, or empirical models (e.g., alpha-power law delay tracking, lumped RC parasitics); NOT directly measured in silicon or discrete characterized Liberty libraries.
4. **[INCOMPLETE-WIP]**: Incomplete flow step or missing tool dependency (e.g., full Netgen LVS requiring OpenCircuitDesign Netgen); active development in progress.
5. **[CORRECTED-DEFECT]**: Script or documentation defect identified during source audit and repaired in milestone `v1.3.0` (e.g., DRC fail-open parsing, CPM direct-wire taps, CDC multi-bit skew).

---

## 2. Complete Subsystem Claim Classification Matrix

| Subsystem / Metric | Published Value in v1.2.0 | v1.3.0 Technical Classification | Engineering Explanation & Current Ground Truth |
|---|---|:---:|---|
| **Critical Path Monitor (CPM)** | 8-tap delay line measuring timing margin | **[CORRECTED-DEFECT]** | In v1.2.0, `tap_wire[i] = tap_wire[i-1]` directly wired all taps together without delay elements. In v1.3.0, replaced with real structural delay buffer stages with keep attributes. |
| **Bandgap Reference (BGR)** | $1.201\text{ V}$, $18.4\text{ ppm/°C}$ | **[SIMPLIFIED-MODEL]** | Generated in `analog/bgr/bgr_1v2.sp` using simplified Level-1 MOS models and generic diode models (`D_PNP_1X`), not foundry SkyWater BSIM/PNP substrate models. |
| **5-bit R-String DAC** | $\text{DNL} = +0.12\text{ LSB}$, $\text{INL} = +0.21\text{ LSB}$ | **[SIMPLIFIED-MODEL]** | Generated using behavioral voltage-controlled switch sources (`Bdec*`), not a full transistor-level digital decoder. |
| **LDO Regulator Loop Gain** | $68.4\text{ dB Gain}$, $74.92^\circ\text{ PM}$, $11.62\text{ MHz UGBW}$ | **[SIMPLIFIED-MODEL]** | Simulated using Level-1 MOS models with Middlebrook AC loop-break probe; valid for architectural proof-of-concept, requires foundry BSIM models for sign-off. |
| **LDO Post-PEX Phase Margin** | $73.85^\circ\text{ PM}$, $42.1\text{ mV Droop}$ | **[CORRECTED-DEFECT]** | In v1.2.0, `run_pex.py` injected manually written RC strings into SPICE. Corrected to parse genuine Magic layout parasitic extractions. |
| **Analog Layout DRC** | 0 DRC violations (`analog_drc.rpt`) | **[CORRECTED-DEFECT]** | Magic 8.3 executed on layouts, but regex parser previously defaulted to 0 if output was unparsed (fail-open). Corrected in v1.3.0 to strict fail-closed assertion. |
| **Layout Versus Schematic (LVS)**| 100% Match, 0 mismatches (`analog_lvs.rpt`)| **[INCOMPLETE-WIP]** | Real Netgen binary was not executed in v1.2.0. Script performed topological netlist parsing. Corrected to state structural match only until OpenCircuitDesign Netgen is integrated. |
| **Discrete STA Timing (Pre-Route)**| TT (+4.12ns), SS (+1.48ns), FF (+7.85ns) | **[TOOL-VERIFIED]** | OpenSTA 2.6 executed on gate netlist against discrete Sky130 Liberty libraries: TT (1.80V, 25C), SS (1.40V, -40C), FF (1.95V, -40C). |
| **Sub-1.40V Core Timing (0.90V)**| Setup slack $+0.94\text{ ns}$ at $0.90\text{ V}, 125\text{ °C}$ | **[MODELED-EXTRAPOLATED]** | The open-source Sky130 PDK does NOT contain discrete 0.90V or 125°C Liberty files. These operating points are modeled via alpha-power law delay scaling from the 1.40V SS library. |
| **Core Clock Frequency Target**| $75.0\text{ MHz}$ ($T = 13.33\text{ ns}$) | **[TOOL-VERIFIED]** | Top-level SDC (`sta/sdc/avs_top.sdc`) and RTL testbenches target 75.0 MHz. (References to 50 MHz in documentation were typos and have been reconciled). |
| **AVS Controller FSM** | 5-state FSM with emergency override | **[CORRECTED-DEFECT]** | The RTL contains 6 states (`ST_RESET`, `ST_WAIT_SETTLE`, `ST_SAMPLE`, `ST_EVALUATE`, `ST_UPDATE_STEP`, `ST_EMERGENCY`). Corrected across all documentation. |
| **Emergency Voltage Response** | 1-cycle emergency response | **[CORRECTED-DEFECT]** | Emergency detection is evaluated synchronously inside `always @(posedge clk_ctrl)`. Maximum latency is 1 controller clock period ($\le 80\text{ ns}$ at 12.5 MHz), not an asynchronous analog override. |
| **Clock Domain Crossing (CDC)**| Multi-bit 2-flop margin synchronizer | **[CORRECTED-DEFECT]** | Sampling multi-bit margin directly across asynchronous domains introduces bit-parallel skew hazards. Hardened with Gray-code bus synchronization in v1.3.0. |
| **Core MAC Dynamic Energy Savings**| $50.61\%$ core energy reduction | **[SIMPLIFIED-MODEL]** | Modeled for pipelined 16-bit MAC under active LFSR burst ($P \propto V^2$) scaling from 1.50V down to 1.054V. |
| **Total System Energy Savings** | $41.43\%$ total energy reduction | **[SIMPLIFIED-MODEL]** | System-level energy accounting including LDO series pass device $V_{drop} \times I_{load}$ linear dissipation and $I_q$ quiescent current. |
| **Steady-State TT Lock Point** | $37.12\%$ energy reduction | **[MODELED-EXTRAPOLATED]** | Continuous closed-loop benchmark lock point in `reports/pvt_cross_corner_matrix.rpt` for nominal TT corner. |
| **Silicon Validation Claim** | None | **[INCOMPLETE-WIP]** | Reaffirmed: Macro is an EDA design, modeling, and simulation flow. No physical silicon fabrication or laboratory bench testing has occurred. |

---

## 3. Discrepancy Reconciliation Summary

### 3.1 Timing Specification Reconciliation
- **Authoritative Frequency**: The system datapath is constrained at **$75.0\text{ MHz}$ ($T_{clk} = 13.333\text{ ns}$)** in `sta/sdc/avs_top.sdc`.
- **Controller Frequency**: The control FSM operates on **$12.5\text{ MHz}$ ($T_{ctrl} = 80.0\text{ ns}$)**.
- **Documentation Fix**: All conflicting mentions of 50.0 MHz in `docs/verification_plan.md` have been corrected to 75.0 MHz.

### 3.2 Energy Reduction Metric Reconciliation
Energy figures reported across different files represent distinct operating regimes and are reconciled as follows:
1. **$50.61\%$ — Core Logic Dynamic Reduction**: Represents purely the MAC datapath $C_{eff} V^2 f$ power scaling from $1.50\text{ V}$ down to $1.054\text{ V}$.
2. **$41.43\%$ — Total Macro System Reduction**: Accounts for LDO linear pass-transistor drop $(1.80\text{ V} - 1.054\text{ V}) \times I_{load}$ and regulator quiescent current ($65\text{ }\mu\text{A}$) during a dynamic $60\text{ }\mu\text{s}$ compute burst.
3. **$37.12\%$ — Steady-State TT PVT Matrix Value**: Represents the nominal steady-state lock point in the 6-corner characterization table under fixed continuous throughput.

### 3.3 Static Timing Library Characterization Limits
- SkyWater 130nm production Liberty files provided in this flow:
  - `sky130_fd_sc_hd__tt_025C_1v80.lib` (Nominal 1.80 V, 25 °C)
  - `sky130_fd_sc_hd__ss_n40C_1v40.lib` (Slow 1.40 V, -40 °C)
  - `sky130_fd_sc_hd__ff_n40C_1v95.lib` (Fast 1.95 V, -40 °C)
- Sign-off results below 1.40 V (such as 0.90 V or 1.054 V) are explicitly labeled as **modeled using SPICE-calibrated alpha-power delay scaling**, as foundry standard cell characterizations are unavailable at those voltages.

---

## 4. Verification Architecture Roadmap for v1.3.0

```
Phase 1: Verification Claim Audit & Evidence Cleanup (DONE)
Phase 2: CPM Hardware Redesign & Timing Calibration (In Progress)
Phase 3: Controller FSM & CDC Gray-Code Hardening (In Progress)
Phase 4: Fail-Closed DRC, Genuine Magic Extraction, and Structural LVS (In Progress)
Phase 5: Reproducible Multi-Level CI Pipeline (Fast CI vs EDA Sign-off)
```
