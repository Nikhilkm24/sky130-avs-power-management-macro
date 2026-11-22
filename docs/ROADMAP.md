# 12-Week Engineering Roadmap: Closed-Loop AVS Power Management Macro on Sky130

| Phase | Milestone Name | Timeline | Key Engineering Deliverables | EDA Toolchain (WSL) | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Phase 0** | **Spec & Infrastructure Setup** | Week 1 | Git repo layout, toolchain validation, specification freezing, top-level architecture | Git, WSL, Yosys, Icarus, OpenSTA, ngspice | **IN PROGRESS** |
| **Phase 1** | **Analog Foundation Subsystem** | Weeks 2–3 | 5-bit R-string DAC, 1.2V BGR, LDO with compensation, AC/transient analysis | ngspice, Python | PLANNED |
| **Phase 2** | **Digital RTL & Verification** | Weeks 3–4 | Critical Path Monitor (CPM), AVS FSM controller, 16-bit pipelined MAC load | Icarus Verilog, GTKWave, cocotb | PLANNED |
| **Phase 3** | **STA Deep-Dive & Correlation** | Weeks 5–6 | MCMM SDC, multi-corner STA, SPICE vs OpenSTA delay correlation table | OpenSTA, ngspice, Python | PLANNED |
| **Phase 4** | **Multi-Voltage Physical Design** | Weeks 7–8 | Macro floorplan, dual-rail PDN, level-shifter insertion, post-route STA | OpenLane2, OpenROAD, Yosys | PLANNED |
| **Phase 5** | **Analog Layout & Sign-off** | Weeks 9–10 | Common-centroid DAC, PMOS pass layout, DRC/LVS/PEX sign-off | Magic, Netgen, KLayout | PLANNED |
| **Phase 6** | **System Validation & Portfolio** | Weeks 11–12 | Full closed-loop transient, energy-per-op curves, datasheet, Git portfolio | Python, ngspice, Matplotlib | PLANNED |

---

## Detailed Phase Breakdown

### Phase 0: Specification, Interface Contracts & Environment (Week 1)
- [x] Create standardized modular Git directory structure (`analog/`, `rtl/`, `pd/`, `sta/`, `sim/`, `models/`, `docs/`, `scripts/`).
- [x] Configure Linux EDA toolchain inside WSL (Ubuntu 24.04):
  - Digital Synthesis: **Yosys 0.33**
  - Functional Simulation: **Icarus Verilog 12.0**
  - Static Timing Analysis: **OpenSTA 3.1.0**
  - Analog SPICE Simulation: **ngspice-42**
  - Standard Cell Timing Libraries: **Sky130 HD / HS (.lib)**
- [x] Define electrical specifications:
  - Input Supply: $V_{DD,IO} = 1.8\text{ V}$ nominal
  - Regulated Supply: $V_{DD,CORE} = 0.90\text{ V} - 1.50\text{ V}$ (5-bit programmable setpoint, $\approx 19.35\text{ mV/step}$)
  - Target Frequency: $50\text{ MHz} - 100\text{ MHz}$
  - Target Timing Margin: 2-3 buffer taps of guard-band under nominal conditions
- [x] Author comprehensive architecture specification and interview guide documents.

---

### Phase 1: Analog Foundation Subsystem (Weeks 2–3)
- **1.1 Bandgap Reference (BGR)**
  - Sky130 PNP substrate bipolar based reference providing stable $1.20\text{ V} \pm 10\text{ mV}$ across $-40^\circ\text{C}$ to $125^\circ\text{C}$.
  - Temperature coefficient $< 25\text{ ppm}/^\circ\text{C}$.
- **1.2 5-Bit Resistor-String Reference DAC**
  - 32-tap unit-resistor string using Sky130 poly or precision thin-film resistor models.
  - Transmission-gate analog multiplexer decoding 5-bit voltage control word $V_{CODE}[4:0]$.
  - Measure INL/DNL ($< 0.5\text{ LSB}$) and monotonic step response.
- **1.3 Programmable Low-Dropout (LDO) Regulator**
  - Two-stage folded-cascode or Miller-compensated error amplifier.
  - Sized PMOS pass transistor ($W/L$) optimized for $I_{LOAD,MAX} = 50\text{ mA}$ with dropout $V_{DO} < 200\text{ mV}$ at 1.5V output.
  - Frequency compensation network: On-chip or off-chip capacitor ensuring Phase Margin $> 50^\circ$ across all load currents ($0.1\text{ mA} - 50\text{ mA}$).
  - Transient load response: $\Delta V_{OUT} < 50\text{ mV}$ for $10\text{ mA}/\text{ns}$ load steps.
- **1.4 Behavioral Modeling**
  - Extract parameter table ($V_{OUT}(V_{CODE})$, settling time $\tau_{settle}$, output impedance $R_{out}$, step slew rate) into Python discrete-time model for digital closed-loop co-simulation.

---

### Phase 2: Digital RTL & Functional Verification (Weeks 3–4)
- **2.1 Replica Critical Path Monitor (CPM)**
  - Tunable replica delay chain mirroring the worst-case combinational path of the digital load.
  - Tapped inverter/buffer delay line (8-16 taps) sampled on the active clock edge.
  - Thermometer-to-binary margin encoder producing real-time `timing_margin[3:0]`.
- **2.2 AVS Controller Finite State Machine (FSM)**
  - Closed-loop tracking algorithm with configurable target margin window (e.g., target = 2 taps).
  - Hysteresis band to eliminate limit-cycle voltage oscillations / chattering.
  - Programmable step limiter (max 1 LSB per update interval).
  - Programmable floor ($V_{MIN} = 0.9\text{ V}$) and ceiling ($V_{MAX} = 1.5\text{ V}$) clamps.
  - Emergency fault detection: If margin drops to 0 (timing hazard), instantly trigger safe-fallback to $V_{MAX}$.
- **2.3 Pipelined Digital Load Block**
  - 16-bit pipelined Multiply-Accumulate (MAC) / 32-bit CRC calculation engine.
  - Dynamic activity factor generator toggling between low-power idle (5% switching) and high-stress compute bursts (85% switching).
- **2.4 RTL Verification**
  - Icarus Verilog testbenches verifying FSM state transitions, margin tracking, step clamping, and emergency recovery.

---

### Phase 3: Static Timing Analysis (STA) Deep-Dive (Weeks 5–6)
- **3.1 SDC Timing Constraints**
  - Multi-clock definitions: Controller clock ($10\text{ MHz} - 25\text{ MHz}$) and Core load clock ($50\text{ MHz} - 100\text{ MHz}$).
  - Clock uncertainty, jitter, transition derates, input/output port constraints.
  - Asynchronous Clock Domain Crossing (CDC) false paths and synchronizer FIFO constraints.
- **3.2 Multi-Corner Multi-Mode (MCMM) Analysis**
  - Characterize load netlist with OpenSTA across Sky130 corners:
    - Typical: `sky130_fd_sc_hd__tt_025C_1v80.lib`
    - Fast-Fast: `sky130_fd_sc_hd__ff_n40C_1v95.lib`
    - Slow-Slow: `sky130_fd_sc_hd__ss_n40C_1v40.lib`
- **3.3 SPICE vs. OpenSTA Delay Calibration**
  - Simulate replica cell path in ngspice across $0.9\text{ V}$ to $1.8\text{ V}$ in $50\text{ mV}$ increments.
  - Correlate SPICE propagation delay against OpenSTA calculated cell delays.
  - Calibrate CPM tap spacing to guarantee positive setup slack across all PVT operating points.

---

### Phase 4: Multi-Voltage Physical Design Flow (Weeks 7–8)
- **4.1 Architecture Partitioning & Level Shifting**
  - Hardened Core Macro (VDD_CORE: $0.9\text{ V} - 1.5\text{ V}$) containing Load + CPM.
  - Hardened Top / Controller Macro (VDD_1V8: $1.8\text{ V}$) containing AVS FSM + DAC interface.
  - Level-shifter insertion (`sky130_fd_sc_hd__lpflow_lsbuf_*`) across domain boundaries.
- **4.2 Synthesis with Yosys**
  - Gate-level mapping using Sky130 HD standard cell library.
  - Area, cell count, and gate density optimization.
- **4.3 Physical Placement & PDN Analysis**
  - Floorplan with dedicated power rings and dual-rail power grid (`VDD_1V8`, `VDD_CORE`, `VSS`).
  - OpenROAD power grid IR-drop analysis under maximum current load.

---

### Phase 5: Analog Layout & DRC/LVS Verification (Weeks 9–10)
- **5.1 5-Bit Resistor DAC Layout**
  - Common-centroid cross-quad unit resistor arrangement.
  - Guard rings and dummy resistor terminations to cancel edge etch variation.
- **5.2 PMOS Pass Transistor Layout**
  - Multi-finger interdigitated PMOS layout with source/drain metal strap sharing.
  - Wide top-metal (met4/met5) routing sized for electromigration (EM) limits at $50\text{ mA}$.
- **5.3 Physical Verification**
  - DRC clean execution using Magic / KLayout.
  - LVS extraction and netlist match with Netgen.
  - Parasitic Extraction (PEX) for post-layout SPICE re-simulation.

---

### Phase 6: System Validation, Energy Measurement & Portfolio (Weeks 11–12)
- **6.1 Closed-Loop Transient Co-Simulation**
  - Simulated dynamic workload step causing sudden core voltage sag.
  - Closed-loop recovery demonstrating AVS FSM adaptation in $< 20\ \mu\text{s}$.
- **6.2 Energy Optimization Metric**
  - Total Energy per Operation ($E_{op} = C_{eff} V_{DD}^2 + V_{DD} I_{leak} T_{op}$) evaluated across:
    - Fixed worst-case signoff voltage ($1.50\text{ V}$)
    - Adaptive voltage scaling ($0.95\text{ V} - 1.10\text{ V}$)
  - Quantify headline result: **35% - 55% energy-per-op reduction**.
- **6.3 Comprehensive Git Repository & Publication**
  - Complete reproducible scripts (`make sim`, `make sta`, `make model`).
  - Production-ready README with architecture diagrams, waveform graphs, and timing tables.
