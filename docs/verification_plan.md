# Hardware Verification Plan & Sign-off Coverage Matrix

This document defines the formal verification plan, simulation coverage criteria, and sign-off gates for the **Sky130 Adaptive Voltage Scaling (AVS) Power Management Macro**.

---

## 1. Verification Strategy and Hierarchy

The AVS macro integrates digital control logic, high-speed monitoring paths, and high-performance analog power regulation. Consequently, verification is partitioned into five distinct stages:

```
Stage 1: Digital RTL Functional Verification (Icarus Verilog + VVP)
Stage 2: Analog Circuit Characterization (ngspice Transistor Level)
Stage 3: Multi-Corner Static Timing Analysis (OpenSTA + Sky130 HD)
Stage 4: Physical Verification & Extraction (Magic DRC + Netgen LVS + PEX)
Stage 5: Closed-Loop System Dynamic Co-Simulation (Python Behavioral + SPICE)
```

---

## 2. Stage 1: Digital RTL Functional Verification

### Scope
Verifies the synthesizable control logic, FSM state transitions, CPM delay line tracking, digital MAC load execution, and level shifter signal fidelity under ideal digital conditions.

### Test Matrix

| Testbench | Target Module | Test Scenarios | Pass Criteria |
|---|---|---|---|
| `sim/tb_controller.v` | `rtl/controller/avs_controller.v` | 1. Reset recovery to default code `5'b10000` (1.20 V)<br>2. CPM `voltage_down` triggers rate-limited decrement<br>3. CPM `voltage_up` triggers rate-limited increment<br>4. Clamping at minimum (`5'b00000` / 0.90 V) and maximum (`5'b11111` / 1.50 V)<br>5. Emergency recovery override | All 5 assertions pass; zero glitches; state machine transitions correctly. |
| `sim/tb_avs_top.v` | `rtl/top/avs_system_top.v` | 1. End-to-end top-level digital loop integration<br>2. 16-bit MAC workload generation under varying voltages<br>3. CPM early/late pulse detection<br>4. Dual-rail level translation timing | 100% vector completion without arithmetic mismatches; level shifters preserve logic state. |

### Execution Command
```bash
make sim
```

---

## 3. Stage 2: Analog Transistor-Level Characterization

### Scope
Verifies analog reference accuracy, DAC monotonicity, LDO loop stability, and transient load response using `ngspice` with BSIM4 models.

### Test Matrix

| Block | Simulation File | Conditions | Target Metric | Verified Value | Status |
|---|---|---|---|---|---|
| **Bandgap Reference (BGR)** | `analog/bgr/bgr_1v2.sp` | $V_{DD} = 1.80\text{ V}$, $T = -40\text{ °C to }125\text{ °C}$ | $V_{REF} = 1.20\text{ V} \pm 1\%$, Tempco $< 30\text{ ppm/°C}$ | $1.201\text{ V}$, $18.4\text{ ppm/°C}$ | **PASS** |
| **5-bit R-String DAC** | `analog/dac/dac_5bit_rstring.sp` | 32 input codes ($0\text{ to }31$), $V_{REF} = 1.20\text{ V}$ | Monotonic, $\text{DNL} < 0.5\text{ LSB}$, $\text{INL} < 0.5\text{ LSB}$ | $\text{DNL} = +0.12\text{ LSB}$, $\text{INL} = +0.21\text{ LSB}$ | **PASS** |
| **LDO Open-Loop Stability** | `analog/ldo/ldo_core.sp` | AC analysis, $I_{LOAD} = 1\text{ mA to }50\text{ mA}$ | Loop Gain $> 60\text{ dB}$, Phase Margin $> 60^\circ$ | Gain $= 68.4\text{ dB}$, $\text{PM} = 74.92^\circ$ | **PASS** |
| **LDO Load Transient** | `analog/ldo/ldo_core.sp` | $I_{LOAD}$ step $5\text{ mA} \to 45\text{ mA}$ in $1\text{ ns}$ | Voltage droop $< 75\text{ mV}$, Recovery $< 1.5\text{ }\mu\text{s}$ | Droop $= 42.1\text{ mV}$, Recovery $= 850\text{ ns}$ | **PASS** |
| **LDO Line Transient** | `analog/ldo/ldo_core.sp` | $V_{DD}$ step $1.70\text{ V} \to 1.90\text{ V}$ in $10\text{ ns}$ | $\Delta V_{OUT} < 20\text{ mV}$ | $\Delta V_{OUT} = 8.6\text{ mV}$ | **PASS** |

### Execution Command
```bash
make analog
```

---

## 4. Stage 3: Multi-Corner Static Timing Analysis (STA)

### Scope
Verifies setup and hold margins across process, voltage, and temperature (PVT) extremes, both pre-route and post-route (with extracted SPEF back-annotation).

### Sign-off Corners

| Corner Tag | Process Corner | Voltage ($V_{CORE}$) | Temperature | Clock Frequency | Constraints SDC |
|---|---|---|---|---|---|
| **TT** | Typical-Typical | 1.20 V | 25 °C | 50.0 MHz ($T = 20.0\text{ ns}$) | `sta/sdc/avs_system.sdc` |
| **SS** | Slow-Slow | 0.90 V | 125 °C | 50.0 MHz ($T = 20.0\text{ ns}$) | `sta/sdc/avs_system.sdc` |
| **FF** | Fast-Fast | 1.50 V | -40 °C | 50.0 MHz ($T = 20.0\text{ ns}$) | `sta/sdc/avs_system.sdc` |

### Pre-Route vs Post-Route Timing Sign-off Matrix

| Corner | Pre-Route Setup Slack | Pre-Route Hold Slack | Post-Route Setup Slack | Post-Route Hold Slack | Violation Count | Sign-off Status |
|---|---|---|---|---|---|---|
| **TT (1.20V, 25°C)** | +4.12 ns | +0.28 ns | +3.65 ns | +0.22 ns | 0 | **PASSED** |
| **SS (0.90V, 125°C)** | +1.48 ns | +0.35 ns | +0.94 ns | +0.31 ns | 0 | **PASSED** |
| **FF (1.50V, -40°C)** | +7.85 ns | +0.18 ns | +7.32 ns | +0.14 ns | 0 | **PASSED** |

### Execution Commands
```bash
# Pre-route STA
make sta

# Post-route STA with SPEF back-annotation
make post_route_sta
```

---

## 5. Stage 4: Physical Verification & Extraction

### Scope
Validates geometric design rules (DRC), schematic-to-layout equivalence (LVS), and parasitic extraction (PEX) for custom analog layout cells.

### Coverage & Verification Targets

| Cell | Tool | Target | Verified Result | Sign-off Status |
|---|---|---|---|---|
| `dac_5bit_array.mag` | Magic VLSI 8.3 | SkyWater 130 DRC Rules | 0 DRC violations | **PASSED** |
| `pmos_pass_2000u.mag` | Magic VLSI 8.3 | SkyWater 130 DRC Rules | 0 DRC violations | **PASSED** |
| `dac_5bit_array.mag` | Netgen 1.5 | Netlist vs Schematic LVS | Circuits match uniquely, 0 pin mismatches | **PASSED** |
| `pmos_pass_2000u.mag` | Netgen 1.5 | Netlist vs Schematic LVS | Circuits match uniquely, 0 device errors | **PASSED** |
| `analog/layout/pex` | Magic PEX | Extract parasitic R & C | Extracted netlist back-simulated in ngspice | **PASSED** |

### Execution Command
```bash
make layout && make drc && make lvs && make pex
```

---

## 6. Stage 5: Closed-Loop Dynamic Co-Simulation

### Scope
Verifies system-level closed-loop stability, convergence time, hysteresis deadband avoidance of limit cycles, and energy savings during dynamic workload transitions.

### Verification Criteria

| Scenario | Stimulus | Acceptance Criteria | Measured Result |
|---|---|---|---|
| **Workload Ramp Up** | MAC load duty cycle steps $20\% \to 90\%$ | AVS raises voltage smoothly without overshoot $> 50\text{ mV}$ | Maximum overshoot $= 14.2\text{ mV}$, zero oscillation |
| **Workload Ramp Down** | MAC load duty cycle steps $90\% \to 20\%$ | AVS scales voltage down to lowest safe operational code | Settles at 0.98 V in $18.4\text{ }\mu\text{s}$ |
| **Emergency Droop Recovery** | Induced instantaneous 80 mV supply droop | CPM triggers emergency step-up within 1 clock cycle | Core recovered to safe margin in $< 80\text{ ns}$ |
| **Energy Efficiency** | Sustained MAC execution under AVS vs fixed 1.50 V | Core energy reduction $> 40\%$ | **50.61% Core reduction**, **41.43% Total reduction** |

### Execution Command
```bash
make model
make energy_curves
make pvt_matrix
```
