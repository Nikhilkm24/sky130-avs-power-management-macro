# Closed-Loop Adaptive Voltage Scaling (AVS) Power Management Macro

[![PDK: Sky130](https://img.shields.io/badge/PDK-Sky130A-blue.svg)](https://github.com/google/skywater-pdk)
[![Tool: OpenSTA](https://img.shields.io/badge/STA-OpenSTA_3.1-orange.svg)](https://github.com/The-OpenROAD-Project/OpenSTA)
[![Tool: Yosys](https://img.shields.io/badge/Synthesis-Yosys_0.33-brightgreen.svg)](https://github.com/YosysHQ/yosys)
[![Tool: ngspice](https://img.shields.io/badge/SPICE-ngspice_42-red.svg)](https://ngspice.sourceforge.io/)
[![Simulation: Icarus Verilog](https://img.shields.io/badge/Verilog-Icarus_12.0-yellow.svg)](http://iverilog.icarus.com/)
[![CI: Automated Verification](https://github.com/Nikhilkm24/sky130-avs-power-management-macro/actions/workflows/ci.yml/badge.svg)](https://github.com/Nikhilkm24/sky130-avs-power-management-macro/actions/workflows/ci.yml)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

---

## 1. Project Overview

Digital integrated circuits are traditionally signed off under worst-case static assumptions. To guarantee correct operation under extreme circumstances, timing closure is performed at the Slow-Slow (SS) process corner, minimum expected operating temperature, and an assumed negative supply voltage droop (often $-10\%$), augmented by an On-Chip Variation (OCV) derating factor. When the manufactured circuit operates under typical ambient conditions and nominal silicon characteristics, these static timing margins become excessive. Because CMOS dynamic power dissipation scales quadratically with supply voltage ($P_{dyn} \propto C_{eff} V_{DD}^2 f$), maintaining a static, worst-case supply rail results in substantial unnecessary energy loss.

Adaptive Voltage Scaling (AVS) addresses this inefficiency by converting open-loop static margin into a closed-loop feedback control system. An on-chip timing monitor tracks real-time circuit delay under the active operating environment, while a digital controller dynamically regulates an integrated Low-Dropout (LDO) linear regulator. The supply voltage is adjusted to the minimum level necessary to satisfy timing constraints with a calibrated guard-band.

This repository presents the design, modeling, implementation, and cross-domain verification of a mixed-signal Adaptive Voltage Scaling Power Management Macro designed for the SkyWater 130nm (Sky130) CMOS technology node. The macro integrates an analog bandgap reference, a 5-bit resistor-string DAC, a programmable linear regulator, an in-situ Critical Path Monitor (CPM), an AVS finite state machine (FSM) controller, and a pipelined Multiplier-Accumulator (MAC) digital workload.

---

## 2. Design Motivation and Engineering Objectives

The primary objective of this macro is to evaluate closed-loop voltage scaling in a standard cell digital environment where foundry timing libraries are only characterized at fixed voltage points. 

### 2.1 Voltage-Delay Scaling Dynamics
In sub-micron CMOS devices, propagation delay follows the alpha-power law:

$$t_{pd} \approx \frac{k_{delay} \cdot V_{DD}}{(V_{DD} - V_{th})^\alpha}$$

where $V_{th} \approx 0.45\text{ V}$ and $\alpha \approx 1.35$ for Sky130 standard NMOS devices. At $V_{DD} = 1.50\text{ V}$, the digital datapath exhibits high drive current and brief gate delays, producing excess positive slack at a 75–80 MHz clock target. Lowering the voltage to $1.05\text{ V}$ increases datapath delay toward the cycle boundary while drastically reducing dynamic energy per operation.

### 2.2 Control Stability and Response Constraints
Dynamic voltage adjustment must not introduce supply undershoots that violate instantaneous setup timing. This introduces key design trade-offs:
1. **Regulator Settling vs. Loop Update Latency**: The control FSM must wait for the analog LDO to settle following a voltage step before sampling the timing monitor, preventing limit-cycle oscillation.
2. **Monotonicity**: The reference DAC must be inherently monotonic to prevent sign inversion in the control loop transfer function.
3. **Emergency Fault Handling**: Acute voltage sags caused by sudden workload bursts must trigger an asynchronous override that restores the safe sign-off ceiling in a single clock cycle.

---

## 3. System Architecture

The macro comprises two voltage domains: a static $1.80\text{ V}$ analog and I/O domain ($V_{DD,1V8}$) and a variable regulated core domain ($V_{DD,CORE}$, spanning $0.90\text{ V}$ to $1.50\text{ V}$).

```
                 VDD_1V8 (1.80V Static Domain)                          VDD_CORE (0.90V - 1.50V Regulated Domain)
+------------------------------------------------------+      +-------------------------------------------------------+
|                                                      |      |                                                       |
|  +--------------------+      +--------------------+  |      |   +-----------------------------------------------+   |
|  | Bandgap Reference  |      |   Reference DAC    |  |      |   |            Digital Load Macro                 |   |
|  |    (1.200V Core)   |----->|  (5-Bit R-String)  |  |      |   |  - 16-Bit Pipelined Multiplier-Accumulator    |   |
|  +--------------------+      +--------------------+  |      |   |  - Galois LFSR Dynamic Activity Generator     |   |
|                                        | V_REF       |      |   +-----------------------------------------------+   |
|                                        v             |      |                                                       |
|                              +--------------------+  |      |   +-----------------------------------------------+   |
|                              |   Analog LDO       |=======> |   |      Replica Critical Path Monitor (CPM)      |   |
|                              | Regulated Output   | VDD_CORE|   |  - 16-Stage Replica Logic Delay Chain         |   |
|                              +--------------------+  |      |   |  - 8-Tap Delay Line & Sampling Flip-Flops     |   |
|                                        ^             |      |   |  - Priority Thermometer Slack Decoder         |   |
|                                        |             |      |   +-----------------------------------------------+   |
|                                  v_code[4:0]         |      |                           |                           |
|                                        |             |      |                    margin_code[3:0]                   |
|                                        |             |      |                           |                           |
|  +------------------------------------------------+  |      +---------------------------|---------------------------+
|  |               AVS Controller FSM               |  |                                  |
|  |  - Settling Timer (16 Cycles / 1.28 us)        |<====================================+ (Level-Shifted & Synchronized)
|  |  - Rate-Limited Step Engine (+/- 1 LSB)        |  |
|  |  - Hysteresis Deadband [target, target + 1]    |  |
|  |  - Asynchronous Emergency Clamping (to 1.50V)  |  |
|  +------------------------------------------------+  |
|                                                      |
+------------------------------------------------------+
```

The Bandgap Reference supplies a temperature-compensated $1.200\text{ V}$ reference to the 5-bit resistor-string DAC. The DAC selects an analog voltage ($0.720\text{ V}$ to $1.200\text{ V}$) that feeds the non-inverting terminal of the LDO error amplifier. The LDO regulates $V_{DD,CORE}$ to $1.25 \times V_{REF}$, providing a range of $0.900\text{ V}$ to $1.500\text{ V}$. Inside the variable-voltage core, the CPM samples datapath delay on every core clock edge and encodes the available margin into a 4-bit bus. This bus is level-shifted, synchronized across clock domains, and evaluated by the AVS Controller to adjust the DAC code.

---

## 4. Design and Implementation

### 4.1 Bandgap Reference (BGR)
The BGR (`analog/bgr/bgr_1v2.sp`) provides a low-temperature-coefficient voltage standard for the reference DAC.
- **Topology**: Brokaw-style cell utilizing substrate PNP transistors $Q_1$ (unit emitter) and $Q_2$ ($8\times$ emitter area ratio).
- **PTAT and CTAT Balance**: The proportional-to-absolute-temperature current is generated via $\Delta V_{BE} = \frac{kT}{q} \ln(8)$ across resistor $R_1 = 9.0\text{ k}\Omega$. The complementary-to-absolute-temperature base-emitter voltage $V_{BE1} \approx 0.642\text{ V}$ ($27^\circ\text{C}$) is summed through resistor $R_2 = 79.5\text{ k}\Omega$ and diode $D_3$ to produce nominal $1.200\text{ V}$.
- **OTA Error Amplifier**: A PMOS differential pair ($W/L = 12\mu\text{m} / 0.5\mu\text{m}$) forces node voltages $V_A = V_B$ with wide common-mode rejection.
- **Active Startup**: A self-extinguishing startup circuit prevents the circuit from remaining in a stable zero-current state upon power-up.
- **Buffer**: A transistor-level unity-gain buffer isolates the reference summing node from the resistive loading of the DAC ladder.

### 4.2 Resistor-String DAC
The reference DAC (`analog/dac/dac_5bit_rstring.sp`) converts the 5-bit digital voltage command into an analog reference.
- **Architecture**: 32 unit resistors ($R_{unit} = 500\ \Omega$) connected in series with a bottom offset resistor ($R_{bot} = 23.25\text{ k}\Omega$).
- **Voltage Range**: $R_{bot}$ sets code 0 to $0.720\text{ V}$, while code 31 reaches $1.200\text{ V}$, yielding an average step size of $\approx 15.48\text{ mV}$.
- **Monotonicity**: A resistor string is inherently monotonic because each incremental code taps a sequentially higher node along the resistor chain. This topological property eliminates sign-inversion hazards in the feedback loop.
- **Switch Matrix**: 32 NMOS transmission gates ($W/L = 2\mu\text{m} / 0.15\mu\text{m}$) are addressed by a 5-to-32 decoder.

### 4.3 Programmable LDO Regulator
The linear regulator (`analog/ldo/ldo_core.sp`) converts the unregulated $1.80\text{ V}$ rail to the dynamic $V_{DD,CORE}$ supply.
- **Error Amplifier**: Two-stage operational transconductance amplifier (OTA) with an NMOS differential input pair ($W/L = 20\mu\text{m} / 0.5\mu\text{m}$) and PMOS active current mirror loads.
- **Power Stage**: Interdigitated PMOS pass transistor sized at $W/L = 2000\mu\text{m} / 0.15\mu\text{m}$ (64 parallel fingers of $31.25\mu\text{m}$ each) to deliver up to $50\text{ mA}$ continuous load current with dropout voltage under $150\text{ mV}$.
- **Feedback Network**: Resistor divider ($R_a = 25\text{ k}\Omega, R_b = 100\text{ k}\Omega$) establishing a closed-loop gain of $1 + R_a/R_b = 1.25$, translating the $0.72\text{ V} - 1.20\text{ V}$ DAC range to $0.90\text{ V} - 1.50\text{ V}$.
- **Compensation**: Miller pole-splitting network ($R_C = 3.6\text{ k}\Omega, C_C = 22.0\text{ pF}$) splits the dominant output pole from the internal OTA pole, yielding unconditional stability. Middlebrook loop-gain AC analysis indicates a phase margin of $74.92^\circ$ at schematic level ($73.85^\circ$ post-layout PEX).

### 4.4 Critical Path Monitor (CPM)
The CPM (`rtl/cpm/critical_path_monitor.v`) tracks in-situ datapath delay directly on the regulated supply rail.
- **Replica Chain**: 16 inversion stages modeled after the worst-case combinational path of the digital load. Synthesis attributes (`(* keep = "true" *)`) are applied to all intermediate nets to prevent logic optimization.
- **Tapped Delay Line**: 8 successive buffer taps extend past the nominal critical path delay.
- **Sampling Mechanism**: A toggle flip-flop launches alternating edges into the delay chain. Rising edges of `clk_core` capture the wavefront across all 8 taps into sampling registers.
- **Thermometer Decoder**: A priority encoder converts the sampled wavefront into a 4-bit margin code (0 to 8). A code of 0 denotes that the wavefront failed to reach the first tap, asserting the `timing_hazard` flag.

### 4.5 AVS Controller FSM
The controller (`rtl/controller/avs_controller.v`) governs the closed-loop tracking behavior.
- **Clock Domain**: Operates on `clk_io` ($12.5\text{ MHz}$ to $20\text{ MHz}$) in the $1.80\text{ V}$ domain.
- **States**: `ST_RESET` (0), `ST_WAIT_SETTLE` (1), `ST_SAMPLE` (2), `ST_EVALUATE` (3), `ST_UPDATE_STEP` (4), and `ST_EMERGENCY` (5).
- **Settling Counter**: Following any voltage step, the FSM enters `ST_WAIT_SETTLE` for 16 cycles ($1.28\ \mu\text{s}$ at $12.5\text{ MHz}$), allowing the analog LDO output to settle fully before re-sampling.
- **Hysteresis Window**: Compares sampled margin against $[target\_margin, target\_margin + 1]$. If margin is below target, voltage steps up by 1 LSB; if margin exceeds target $+ 1$, voltage steps down by 1 LSB; otherwise, the loop remains idle (`settled = 1`).
- **Emergency Clamping**: If `margin_code == 0`, an immediate asynchronous override forces `ST_EMERGENCY`, restoring `V_MAX` (Code 31 / $1.50\text{ V}$) in a single clock cycle.

### 4.6 Digital MAC Load Macro
The digital workload (`rtl/load/pipelined_mac_load.v`) provides realistic switching activity and dynamic current transients.
- **Datapath**: 16-bit pipelined Multiplier-Accumulator featuring a 2-stage multiplier and a 2-stage 32-bit accumulator. Splitting the accumulation into 16-bit half-words eliminates long ripple-carry chains, guaranteeing positive slack across all corners.
- **Activity Generator**: Built-in 16-bit Galois LFSR (polynomial $x^{16} + x^{14} + x^{13} + x^{11} + 1$) inducing high-activity pseudo-random compute bursts when `stress_mode` is enabled.

### 4.7 Multi-Voltage Boundary & Clock Domain Crossing
The system bridges two voltage domains and two asynchronous clocks (`rtl/level_shifter/level_shifter.v`, `rtl/top/avs_system_top.v`):
- **Level Shifting**: Low-to-high level shifters map CPM margin and MAC results from $V_{DD,CORE}$ to $V_{DD,1V8}$. High-to-low level shifters step down control signals entering the core.
- **CDC Synchronization**: A double-flip-flop synchronizer safely transfers the 4-bit margin code from the 75 MHz core domain into the 12.5 MHz controller domain. SDC timing constraints declare asynchronous clock groups and enforce `-datapath_only` maximum delay bounds.

---

## 5. Simulation and Verification

The verification strategy evaluates the system across individual block implementations, synthesized gates, extracted layout parasitics, and closed-loop mixed-signal dynamics.

```
+----------------------------------------------------------------------------------------------------+
|                                    VERIFICATION FLOW OVERVIEW                                      |
+--------------------+---------------------+--------------------+--------------------+---------------+
| Analog SPICE       | Digital RTL & Synth | Timing Sign-Off    | Physical Layout    | Mixed-Signal  |
| - BGR Line/Temp    | - Icarus Verilog TB | - OpenSTA (TT/FF/SS| - Magic 8.3 DRC    | - 60us Co-Sim |
| - DAC Linearity    | - Yosys Synthesis   | - Delay Correlation| - Magic LVS Extr.  | - Step Load   |
| - LDO Middlebrook  | - CDC Verification  | - SPEF Post-Route  | - ngspice PEX Sim  | - Fault Recov.|
+--------------------+---------------------+--------------------+--------------------+---------------+
```

### 5.1 Digital RTL Functional Verification
- **Objective**: Verify FSM state transitions, rate-limited stepping, hysteresis locking, and emergency fault recovery.
- **Method**: Simulation using Icarus Verilog (`iverilog -g2012`) with testbenches `sim/tb_controller.v` and `sim/tb_avs_top.v`.
- **Results**: The controller reliably boots at Code 31 ($1.50\text{ V}$), steps down incrementally under excessive margin, settles within the target deadband, and executes single-cycle emergency fallback upon injected timing faults.

### 5.2 Analog SPICE Characterization
- **Objective**: Characterize BGR drift, DAC linearity (DNL/INL), and LDO closed-loop AC stability.
- **Method**: Batch transistor-level simulation in `ngspice-42` (`analog/bgr/bgr_1v2.sp`, `analog/dac/dac_5bit_rstring.sp`, `analog/ldo/ldo_core.sp`).
- **Results**:
  - BGR: $1.200\text{ V}$ nominal output with $66.7\text{ ppm/}^\circ\text{C}$ temperature coefficient ($-40^\circ\text{C}$ to $+125^\circ\text{C}$).
  - DAC: Monotonic across all 32 codes ($0.720\text{ V}$ to $1.200\text{ V}$) with $DNL \le 0.12\text{ LSB}$ and $INL \le 0.18\text{ LSB}$.
  - LDO: DC open-loop gain of $45.8\text{ dB}$, unity-gain bandwidth of $11.62\text{ MHz}$, and phase margin of $74.92^\circ$ at $15\text{ mA}$ load.

### 5.3 Logic Synthesis
- **Objective**: Map synthesizable RTL to the SkyWater 130nm high-density standard cell library (`sky130_fd_sc_hd`).
- **Method**: Logic synthesis in Yosys 0.33 (`synth/synth_top.tcl`).
- **Results**: Synthesized netlist contains 380 standard cell instances. Hierarchical preservation kept the 16 replica delay stages intact without logic absorption.

### 5.4 Static Timing Analysis (STA)
- **Objective**: Verify setup and hold timing closure across discrete foundry PVT corners.
- **Method**: Multi-corner sign-off in OpenSTA 3.1.0 (`sta/scripts/run_sta_corners.tcl`) driven by dual-clock constraints (`sta/sdc/avs_top.sdc`).
- **Results**:
  - Typical (TT, $1.80\text{ V}, 25^\circ\text{C}$): Setup slack = $+5.82\text{ ns}$ (at $80\text{ MHz}$).
  - Fast-Fast (FF, $1.95\text{ V}, -40^\circ\text{C}$): Setup slack = $+6.95\text{ ns}$.
  - Slow-Slow (SS, $1.40\text{ V}, -40^\circ\text{C}$): Setup slack = $+5.127\text{ ns}$.

### 5.5 Delay-Voltage Correlation
- **Objective**: Model continuous delay variation from $0.90\text{ V}$ to $1.50\text{ V}$ to calibrate the CPM delay line against OpenSTA.
- **Method**: Automated SPICE sweeps on standard cell paths fitted to an alpha-power model (`sta/spice_sta_correlate/correlate_sta_spice.py`).
- **Results**: Datapath delay increases from $6.2\text{ ns}$ at $1.50\text{ V}$ to $12.8\text{ ns}$ at $1.05\text{ V}$. Tap 2 of the CPM aligns with the target $360\text{ ps}$ guard-band at the $75\text{ MHz}$ nominal clock frequency.

### 5.6 Mixed-Signal Closed-Loop Co-Simulation
- **Objective**: Verify the dynamic interaction of the analog power macro and digital core under load transitions.
- **Method**: Co-simulation engine (`sim/run_mixed_signal_co_sim.py`, `models/closed_loop_avs_sim.py`) coupling 2nd-order analog LDO state equations with cycle-accurate FSM and CPM tracking across a $60\ \mu\text{s}$ workload.
- **Results**:
  - Voltage steps down smoothly from $1.50\text{ V}$ to $1.054\text{ V}$ (Code 8), locking in $24\ \mu\text{s}$.
  - A $33\text{ mA}$ load burst ($5\text{ mA} \to 38\text{ mA}$) induces a transient droop of only $6.1\text{ mV}$.
  - Injected acute margin collapse triggers emergency recovery in 1 clock cycle, returning the rail to safe ceiling.

### 5.7 Physical Design & Interconnect Parasitics
- **Objective**: Generate floorplans, power distribution networks, and interconnect parasitics.
- **Method**: Custom Python physical design scripts (`pd/scripts/`) modeling Sky130 design rules and metal stack properties, generating standard DEF and IEEE 1481 SPEF files evaluated in OpenSTA (`pd/scripts/run_post_route_sta.tcl`).
- **Results**: Die dimensions of $450\mu\text{m} \times 320\mu\text{m}$. Post-route STA reading extracted SPEF confirms positive setup slack ($+5.127\text{ ns}$) is retained.

### 5.8 Analog Layout Verification (DRC, LVS, PEX)
- **Objective**: Physical sign-off of custom analog macros.
- **Method**: Magic 8.3 batch DRC and extraction (`analog/layout/run_drc.py`, `run_lvs.py`, `run_pex.py`).
- **Results**:
  - DRC: 0 violations across both `dac_5bit_array.mag` and `pmos_pass_2000u.mag`.
  - LVS: Device counts, port connectivity, and geometry matched schematic subcircuits.
  - PEX: Post-layout ngspice simulation with extracted parasitics confirms LDO phase margin remains robust at $73.85^\circ$ ($142.2\text{ mV}$ dropout at $50\text{ mA}$).

---

## 6. Energy Characterization & Measurements

Energy reduction was evaluated through transistor-level SPICE integration over a $20\ \mu\text{s}$ steady-state compute window ($1500\text{ operations}$ at $75\text{ MHz}$), comparing the fixed worst-case sign-off ceiling (Code 31: $1.499\text{ V}$) against the adaptive setpoint (Code 8: $1.054\text{ V}$).

```
+----------------------------------------------------------------------------------------------------+
|                                    ENERGY REDUCTION SUMMARY                                        |
+------------------------------------+--------------------------+--------------------------+---------+
| Metric                             | Fixed Sign-Off (1.499V)  | Adaptive Locked (1.054V) | Delta   |
+------------------------------------+--------------------------+--------------------------+---------+
| Regulated Core Voltage             | 1.499 V                  | 1.054 V                  | -29.72% |
| Core Current (Dynamic Load)        | 10.00 mA                 | 7.02 mA                  | -29.72% |
| Core Power Dissipation             | 14.99 mW                 | 7.40 mW                  | -50.61% |
| Core Energy per Operation          | 199.82 pJ/op             | 98.70 pJ/op              | -50.61% |
| Total 1.8V Supply Current          | 10.22 mA                 | 7.24 mA                  | -29.11% |
| Total 1.8V Input Power             | 18.39 mW                 | 13.04 mW                 | -29.11% |
| Total Supply Energy per Operation  | 245.24 pJ/op             | 173.85 pJ/op             | -29.11% |
+------------------------------------+--------------------------+--------------------------+---------+
```

### Engineering Explanation of the Reduction Discrepancy
A critical observation in this data is the difference between core energy reduction and total supply energy reduction:
1. **Core Energy Reduction ($50.61\%$)**: Inside the digital core, dynamic power scales quadratically with voltage ($P = C_{eff} V_{CORE}^2 f$). Reducing $V_{CORE}$ from $1.499\text{ V}$ to $1.054\text{ V}$ produces a $(1.054 / 1.499)^2 = 0.4939$ scaling factor, reducing core energy per operation by **$50.61\%$**.
2. **Total Supply Energy Reduction ($29.11\%$)**: The LDO is a linear regulator. The current drawn from the external $1.80\text{ V}$ rail equals the load current plus quiescent bias ($I_{in} = I_{load} + I_q$). In a linear regulator, the input supply voltage remains fixed at $1.80\text{ V}$, so input power scales linearly with load current rather than quadratically. The excess voltage $(V_{IN} - V_{CORE})$ is dissipated as heat in the PMOS pass transistor.
3. **Workload Average ($41.43\%$)**: The $41.43\%$ figure reported in closed-loop system simulation reflects the time-weighted average energy saving over the entire multi-phase dynamic benchmark (incorporating initial downscaling, idle states, compute bursts, and post-fault recovery).

---

## 7. Results and Engineering Observations

### 7.1 Electrical Operating Metrics
| Parameter | Value / Range | Unit | Verification Source |
| :--- | :--- | :---: | :--- |
| Unregulated Supply Input ($V_{DD,1V8}$) | 1.62 to 1.98 (1.80 nominal) | V | SPICE testbench |
| Regulated Core Range ($V_{DD,CORE}$) | 0.900 to 1.500 | V | SPICE / DAC sweeps |
| Bandgap Reference Output ($V_{BGR}$) | 1.200 ($\pm 10\text{ mV}$) | V | `analog/bgr/bgr_1v2.sp` |
| BGR Temperature Coefficient | 66.7 | ppm/$^\circ$C | SPICE ($-40^\circ\text{C}$ to $+125^\circ\text{C}$) |
| DAC Resolution / Step Size | 5 bits / 15.48 | mV | `analog/dac/dac_5bit_rstring.sp` |
| DAC Linearity (DNL / INL) | $\le 0.12$ / $\le 0.18$ | LSB | `analog/dac/verify_dac_linearity.py` |
| LDO Dropout Voltage ($50\text{ mA}$) | 138 (schematic) / 142.2 (PEX) | mV | `analog/layout/post_layout_sim.sp` |
| LDO Phase Margin | 74.92 (schematic) / 73.85 (PEX) | deg | Middlebrook AC return ratio |
| LDO Unity Gain Bandwidth | 11.62 | MHz | Middlebrook AC return ratio |

### 7.2 Digital and Timing Metrics
| Parameter | Value | Unit | Verification Source |
| :--- | :--- | :---: | :--- |
| Core Clock Frequency | 75.0 to 80.0 | MHz | SDC constraints / OpenSTA |
| Controller Clock Frequency | 12.5 to 20.0 | MHz | SDC constraints / OpenSTA |
| Pre-Route Setup Slack (TT, $1.80\text{ V}$) | +5.82 | ns | OpenSTA 3.1.0 |
| Pre-Route Setup Slack (SS, $1.40\text{ V}$) | +5.127 | ns | OpenSTA 3.1.0 |
| Post-Route Setup Slack (with SPEF) | +5.127 | ns | OpenSTA reading extracted SPEF |
| Synthesized Standard Cell Count | 380 | cells | Yosys 0.33 synthesis log |
| CPM Replica Delay Chain Length | 16 | stages | `rtl/cpm/critical_path_monitor.v` |
| CPM Tapped Delay Line Steps | 8 (180 ps/tap) | taps | In-situ delay tracking |

---

## 8. Technical Considerations and Current Limitations

A rigorous assessment of this implementation reveals several engineering challenges and boundaries that should be understood by anyone exploring the architecture:

1. **Replica Path Tracking Inaccuracies**: The Critical Path Monitor relies on a 16-stage inverter-dominant delay chain. While inverters exhibit delay-voltage characteristics broadly similar to logic gates, real critical paths contain complex combinations of transmission gates, XOR trees, and routing interconnects. Temperature and process cross-sensitivities can cause the replica path delay to diverge slightly from the actual critical path across skewed corners (FS, SF).
2. **Linear Regulator Thermodynamic Efficiency**: Because this macro uses a linear LDO regulator, total input power scales linearly with current ($P_{in} = 1.80\text{ V} \times I_{core}$). At $V_{CORE} = 1.05\text{ V}$, the LDO operates with an efficiency of $\approx 58\%$, dissipating the remaining energy as heat. Achieving quadratic power reduction at the battery level would require a high-efficiency switching buck converter or hybrid switched-capacitor pre-regulator.
3. **Delay Quantization & Resolution**: The CPM delay line uses discrete buffer taps spaced at $\approx 180\text{ ps}$. The finite resolution introduces a quantization guard-band: the controller must target at least 2 taps ($360\text{ ps}$) of margin to prevent hunting between adjacent codes.
4. **Physical Design Implementation Flow**: Physical design DEF floorplans and SPEF interconnect parasitic netlists were produced via custom Python scripts modeling SkyWater 130nm layout rules and metal stack RC equations, rather than an end-to-end automated OpenROAD / OpenLane execution. OpenSTA was subsequently used to evaluate post-route timing closure against the extracted SPEF.
5. **Silicon Validation Boundary**: All results presented in this repository represent simulations (ngspice-42), gate-level synthesis (Yosys 0.33), timing analyses (OpenSTA 3.1.0), and physical verifications (Magic 8.3). This design has not been fabricated in silicon or validated on a physical test bench.

---

## 9. Repository Organization

```text
sky130-avs-power-management-macro/
├── .github/workflows/ci.yml         # Automated GitHub Actions verification pipeline
├── .agents/rules/                   # Antigravity persistent engineering rules
├── Makefile                         # Unified verification runner
├── LICENSE                          # Proprietary educational license
├── AGENTS.md                        # Persistent engineering standards documentation
├── README.md                        # Primary technical documentation
├── analog/                          # Analog subsystem netlists, layouts, and PEX
│   ├── bgr/bgr_1v2.sp               # Transistor-level 1.20V Bandgap Reference
│   ├── dac/dac_5bit_rstring.sp      # 5-bit Resistor-String DAC netlist
│   ├── dac/verify_dac_linearity.py  # DNL/INL extraction script
│   ├── ldo/ldo_core.sp              # Transistor-level LDO with Middlebrook probe
│   └── layout/                      # Custom Magic layout files and PEX runners
│       ├── dac_5bit_array.mag       # 8x4 common-centroid DAC layout
│       ├── pmos_pass_2000u.mag      # 64-finger PMOS pass device layout
│       ├── run_drc.py               # Magic 8.3 batch DRC execution script
│       ├── run_lvs.py               # Netlist extraction and LVS script
│       └── run_pex.py               # Parasitic extraction and post-layout SPICE
├── rtl/                             # Synthesizable Verilog RTL source files
│   ├── controller/avs_controller.v  # Closed-loop AVS FSM controller
│   ├── cpm/critical_path_monitor.v  # Synthesizable replica delay line and CPM
│   ├── load/pipelined_mac_load.v    # 16-bit pipelined MAC workload with LFSR
│   ├── level_shifter/level_shifter.v# Sky130 multi-voltage level shifters and CDC
│   └── top/avs_system_top.v         # Integrated digital top-level macro
├── sim/                             # Testbenches and mixed-signal simulation
│   ├── tb_controller.v              # FSM controller standalone testbench
│   ├── tb_avs_top.v                 # Integrated digital top testbench
│   ├── mixed_signal_top.sp          # Transistor-level mixed-signal SPICE deck
│   ├── run_mixed_signal_co_sim.py   # Closed-loop co-simulation engine
│   ├── energy_benchmark_fixed.sp    # Fixed 1.50V SPICE energy benchmark
│   └── energy_benchmark_adaptive.sp # Adaptive 1.054V SPICE energy benchmark
├── sta/                             # Static Timing Analysis
│   ├── sdc/avs_top.sdc              # Dual-clock SDC timing constraints
│   ├── scripts/run_sta_corners.tcl  # OpenSTA multi-corner execution script
│   └── spice_sta_correlate/         # SPICE vs STA delay correlation script
├── synth/                           # Logic synthesis
│   ├── synth_top.tcl                # Yosys synthesis script for Sky130 HD
│   └── avs_system_top_netlist.v     # Gate-level mapped netlist (380 cells)
├── pd/                              # Physical design and interconnect modeling
│   ├── scripts/                     # Python floorplan, placement, and SPEF scripts
│   └── results/                     # Generated floorplan.def, placed.def, and SPEF
├── models/                          # Behavioral and numerical modeling
│   ├── ldo_behavioral.py            # 2nd-order analog LDO transfer function
│   ├── closed_loop_avs_sim.py       # Full closed-loop dynamic simulation
│   └── generate_energy_tradeoff_curves.py # Voltage scaling energy trade-off generator
├── reports/                         # Execution logs, sign-off reports, and figures
│   ├── FINAL_PROJECT_SIGNOFF_REPORT.md # Consolidated engineering sign-off report
│   ├── analog_drc.rpt               # Magic DRC execution report (0 errors)
│   ├── analog_lvs.rpt               # Netgen / Magic LVS extraction report
│   ├── analog_pex_comparison.rpt    # Post-layout PEX parameter comparison
│   ├── energy_tradeoff_report.rpt   # SPICE energy integration summary
│   ├── mixed_signal_integration.rpt # 60us dynamic transient report
│   └── pvt_cross_corner_matrix.rpt  # Cross-corner PVT characterization matrix
└── docs/                            # Detailed technical specifications and manuals
    ├── COMPLETE_PROJECT_DOCUMENTATION.md # Comprehensive engineering design manual
    ├── LDO_DATASHEET_SUMMARY.md     # Electrical characteristics table
    ├── SPECIFICATION.md             # Parameter specifications
    ├── SYSTEM_ARCHITECTURE.md       # Block diagrams and theory of operation
    └── ROADMAP.md                   # Development roadmap and milestone logs
```

---

## 10. Future Development Roadmap

1. **Digital Calibration Registers**: Integrate software-programmable trimming registers for the CPM replica chain to compensate for post-fabrication process mismatch.
2. **Hybrid Switching-Linear Architecture**: Investigate adding an integrated switched-capacitor pre-regulator to step $1.80\text{ V}$ down to $\approx 1.25\text{ V}$ with $> 85\%$ efficiency before feeding the linear LDO, recovering quadratic energy savings at the system supply input.
3. **Full Automated OpenLane Macro Hardening**: Complete full OpenROAD-native physical placement, clock tree synthesis, and antenna diode insertion to produce a tapeout-ready GDSII file.
4. **Silicon Fabrication & Test Vehicle**: Submit the hardened macro through an open-source multi-project wafer (MPW) run for physical silicon validation and lab characterization.

---

## 11. Build and Simulation Quick Reference

The verification suite can be executed using the unified Makefile:

| Target | Command | Primary Tools | Output Generated |
| :--- | :--- | :--- | :--- |
| **Digital Simulation** | `make sim` | Icarus Verilog | `sim_controller.vcd`, `sim_avs_top.vcd` |
| **Analog Characterization**| `make analog` | ngspice | `bgr_line_reg.data`, `ldo_loop_gain.data` |
| **Logic Synthesis** | `make synth` | Yosys | `synth/avs_system_top_netlist.v` |
| **Static Timing** | `make sta` | OpenSTA | `reports/sta_tt.log`, `sta_ss.log`, `sta_ff.log` |
| **Physical Design** | `make pd` | Python scripts | `pd/results/floorplan.def`, `avs_system_top.spef` |
| **Post-Route Timing** | `make post_route_sta` | OpenSTA | `reports/post_route_sta_tt.log` |
| **Analog Verification** | `make drc && make lvs && make pex` | Magic 8.3, ngspice | `reports/analog_drc.rpt`, `analog_lvs.rpt` |
| **Full Pipeline** | `make validate` | All tools | Comprehensive cross-domain sign-off |

---

## 12. Design Parameter Summary Table

| Parameter | Symbol | Design Value | Units |
| :--- | :--- | :---: | :---: |
| Primary Input Supply | $V_{DD,1V8}$ | 1.80 | V |
| Regulated Core Range | $V_{DD,CORE}$ | 0.90 to 1.50 | V |
| Core Clock Target | $F_{CORE}$ | 75.0 to 80.0 | MHz |
| Controller Clock | $F_{CTRL}$ | 12.5 | MHz |
| Nominal Regulated Lock Point | $V_{NOM}$ | 1.054 (Code 8) | V |
| LDO Maximum Load Current | $I_{LOAD,MAX}$ | 50.0 | mA |
| PMOS Pass Transistor Geometry | $W / L$ | 2000.0 / 0.15 | $\mu\text{m}$ |
| Compensation Network | $R_C / C_C$ | 3.6 / 22.0 | $\text{k}\Omega\text{ / pF}$ |
| LDO Phase Margin (Post-PEX) | $\phi_M$ | 73.85 | degrees |
| LDO Unity Gain Bandwidth | $f_{UGBW}$ | 11.62 | MHz |
| DAC Resolution / Steps | $N / 2^N$ | 5 / 32 | bits / levels |
| CPM Replica Delay Stages | $N_{REP}$ | 16 | inverters |
| CPM Guard-Band Target | $M_{TARG}$ | 2 | taps ($360\text{ ps}$) |

---

## 13. Subsystem Interface Matrix

| Port Name | Direction | Domain | Width | Functional Description |
| :--- | :---: | :---: | :---: | :--- |
| `clk_io` | Input | $V_{DD,1V8}$ | 1 | Controller reference clock ($12.5\text{ MHz} - 20\text{ MHz}$) |
| `rst_n` | Input | $V_{DD,1V8}$ | 1 | Active-low asynchronous system reset |
| `clk_core` | Input | $V_{DD,CORE}$ | 1 | Variable-voltage core clock ($75\text{ MHz} - 80\text{ MHz}$) |
| `avs_enable` | Input | $V_{DD,1V8}$ | 1 | High = closed-loop tracking, Low = manual override |
| `manual_code` | Input | $V_{DD,1V8}$ | 5 | Manual voltage DAC code when `avs_enable` is low |
| `target_margin`| Input | $V_{DD,1V8}$ | 4 | Target timing guard-band (default: 2 taps) |
| `dac_voltage_code`| Output | $V_{DD,1V8}$ | 5 | Output voltage code driving reference DAC |
| `timing_hazard`| Output | $V_{DD,1V8}$ | 1 | Asserted during acute timing margin collapse |
| `loop_settled` | Output | $V_{DD,1V8}$ | 1 | Asserted when margin is within target hysteresis deadband |
| `fsm_state_out`| Output | $V_{DD,1V8}$ | 3 | Exposed FSM state for system observability |
| `load_enable` | Input | $V_{DD,1V8}$ | 1 | Enables digital MAC computation (level-shifted into core) |
| `stress_mode` | Input | $V_{DD,1V8}$ | 1 | Enables LFSR dynamic compute burst for transient load step |
| `mac_result` | Output | $V_{DD,1V8}$ | 32 | Level-shifted MAC computation output |

---

## 14. License

Copyright © 2026 Nikhil Mahesh  
Cloud Mushroom Operations Centre — All Rights Reserved  

This repository is made available for educational and portfolio reference purposes only. The source code, schematics, documentation, and all associated materials in this repository are proprietary. Unauthorized commercial use, redistribution, modification, or deployment of this system or any derivative thereof without explicit written permission from the author is strictly prohibited.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
