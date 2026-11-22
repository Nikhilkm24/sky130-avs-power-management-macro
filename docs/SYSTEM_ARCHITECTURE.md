# System Architecture & Theory of Operation

## 1. Architectural Block Diagram

```
                 VDD_1V8 (1.8V Domain)                                  VDD_CORE (0.9V - 1.5V Domain)
+------------------------------------------------------+      +-------------------------------------------------------+
|                                                      |      |                                                       |
|  +--------------------+      +--------------------+  |      |   +-----------------------------------------------+   |
|  | Bandgap Reference  |      |   Reference DAC    |  |      |   |            Digital Load Macro                 |   |
|  |     (BGR 1.20V)    |----->|  (5-Bit R-String)  |  |      |   |  - 16-Bit Pipelined Multiplier-Accumulator    |   |
|  +--------------------+      +--------------------+  |      |   |  - LFSR Pseudo-Random Activity Generator      |   |
|                                        | V_REF       |      |   +-----------------------------------------------+   |
|                                        v             |      |                                                       |
|                              +--------------------+  |      |   +-----------------------------------------------+   |
|                              |   Analog LDO       |=======> |   |      Replica Critical-Path Monitor (CPM)      |   |
|                              | Regulated 0.9-1.5V | VDD_CORE|   |  - Exact Replica Delay Chain                  |   |
|                              +--------------------+  |      |   |  - 8-Tap Delay Line & Sampling Flip-Flops     |   |
|                                        ^             |      |   |  - Thermometer Timing Margin Encoder          |   |
|                                        |             |      |   +-----------------------------------------------+   |
|                                  Voltage Code        |      |                           |                           |
|                                     [4:0]            |      |                    raw_margin[3:0]                    |
|                                        |             |      |                           |                           |
|  +------------------------------------------------+  |      +---------------------------|---------------------------+
|  |               AVS Controller FSM               |  |                                  |
|  |  - Hysteresis Window Comparator                |<====================================+ (Level-Shifted & Synchronized)
|  |  - Rate-Limited Step Engine (±1 LSB)           |  |
|  |  - Floor (0.9V) & Ceiling (1.5V) Clamp         |  |
|  |  - Emergency Fault Detector (Instant Fallback) |  |
|  +------------------------------------------------+  |
|                                                      |
+------------------------------------------------------+
```

---

## 2. Theory of Operation

### 2.1 The Traditional Over-Design Problem
In standard digital ASIC flows, timing sign-off occurs at the **Slow-Slow (SS)** corner at the lowest operating temperature (or highest, depending on temperature inversion) under a pessimistic **-10% supply voltage droop** and an additional **8% - 15% On-Chip Variation (OCV)** derate. In real operating conditions (TT corner, room temperature $25^\circ\text{C}$, nominal voltage):
- The physical silicon is **30% to 60% faster** than the sign-off condition.
- This excess speed is wasted as excess voltage, resulting in massive dynamic power wastage ($P \propto V^2$).

### 2.2 Adaptive Voltage Scaling Solution
AVS replaces open-loop pessimistic margins with real-time in-situ closed-loop feedback:
1. **Critical Path Monitor (CPM)** tracks the exact delay of the digital datapath under instantaneous PVT and local thermal conditions.
2. The delay chain is tapped by sampling flip-flops clocked on the same edge as the main datapath.
3. If the signal traverses all taps with margin to spare, the margin code is high $\rightarrow$ **Voltage can be safely reduced**.
4. The **AVS Controller FSM** steps down the reference code to the **5-bit R-String DAC**.
5. The **LDO Regulator** lowers $V_{DD,CORE}$.
6. As $V_{DD,CORE}$ drops, propagation delay increases until the measured margin matches the programmed **Target Margin** (e.g., 2 taps of safety guard-band).
7. If an external event causes a transient supply droop or thermal spike such that timing is endangered (margin code drops to $\le 0$), the **Emergency Fault Detector** overrides the FSM and commands the DAC to jump immediately to the safe maximum ceiling voltage ($1.50\text{ V}$), preventing timing violations.

---

## 3. Subsystem Descriptions

### 3.1 Bandgap Reference (BGR)
- **Topology**: Brokaw cell / Substrate PNP ($Q_1, Q_2$) differential pair with PTAT current generation through resistor $R_1$.
- **Reference Equation**:
  $$V_{REF} = V_{BE2} + \left(\frac{R_2}{R_1}\right) \cdot V_T \ln(N)$$
  where $V_{BE}$ has a complementary-to-absolute-temperature (CTAT) slope ($-1.8\text{ mV}/^\circ\text{C}$) and $V_T \ln(N)$ has a proportional-to-absolute-temperature (PTAT) slope ($+0.086\text{ mV}/^\circ\text{C}$).
- **Target Output**: $1.200\text{ V} \pm 10\text{ mV}$ across $-40^\circ\text{C}$ to $125^\circ\text{C}$.

### 3.2 5-Bit Resistor-String Reference DAC
- **Topology**: 32 equal unit resistors ($R = 500\ \Omega$) connected between $V_{REF}$ and ground.
- **Decoder**: 5-to-32 transmission-gate analog multiplexer.
- **Output Setpoint**:
  $$V_{DAC}[k] = V_{BGR} \cdot \left(\frac{k+1}{32}\right), \quad k \in [0, 31]$$
- **Monotonicity**: An R-string is inherently monotonic by construction, preventing loop instability or sign inversion in the AVS controller.

### 3.3 Programmable Low-Dropout (LDO) Regulator
- **Topology**: PMOS pass transistor ($M_{PASS}$), error amplifier (folded-cascode), resistive feedback divider ($R_A, R_B$), and Miller frequency compensation.
- **Transfer Function**:
  $$V_{DD,CORE} = V_{DAC} \cdot \left(1 + \frac{R_A}{R_B}\right)$$
  Selecting $R_A / R_B = 0.25$ maps the DAC output ($0.72\text{ V} - 1.20\text{ V}$) to $V_{DD,CORE} \in [0.90\text{ V}, 1.50\text{ V}]$.
- **Loop Dynamics**:
  - Open-loop DC gain $A_0 > 65\text{ dB}$.
  - Dominant pole at the gate of $M_{PASS}$.
  - Miller compensation capacitor $C_C \approx 4\text{ pF}$ provides pole-splitting, guaranteeing $\phi_M > 55^\circ$ across load range $0.1\text{ mA} \le I_L \le 50\text{ mA}$.

### 3.4 Replica Critical Path Monitor (CPM)
- **Replica Chain**: Synthesized chain matching the logic topology of the 16-bit MAC (XOR, AND-OR-INVERT, Full Adders, routing delay).
- **Tapped Delay Line**: 8 successive inverter/buffer pairs extending beyond the nominal delay.
- **Sampling Registers**: Parallel D flip-flops capturing the propagation wavefront on the rising clock edge.
- **Thermometer Encoding**:
  - `8'b1111_1111` $\rightarrow$ Maximum margin (excessive headroom, step down).
  - `8'b0000_0111` $\rightarrow$ Nominal safe margin (3 taps).
  - `8'b0000_0011` $\rightarrow$ Target margin (2 taps, lock loop).
  - `8'b0000_0001` $\rightarrow$ Danger margin (1 tap, step up immediately).
  - `8'b0000_0000` $\rightarrow$ Timing violation hazard (trigger emergency fallback).

### 3.5 AVS Controller Finite State Machine
- **State Machine States**:
  1. `RESET_INIT`: Initialize DAC to safe ceiling voltage $V_{MAX} = 1.50\text{ V}$ (`v_code = 5'd31`).
  2. `WAIT_SETTLE`: Wait for LDO settling counter ($N_{SETTLE} = 16$ clock cycles).
  3. `SAMPLE_MARGIN`: Capture synchronized thermometer margin code from CPM.
  4. `EVALUATE`:
     - If `margin == 0`: Transition to `EMERGENCY_RECOVERY`.
     - If `margin < TARGET_MARGIN`: Decrement voltage margin $\rightarrow$ Increment $V_{CODE}$ (step up voltage).
     - If `margin > TARGET_MARGIN + HYSTERESIS`: Step down voltage (decrement $V_{CODE}$).
     - If `margin` within hysteresis window: Maintain current $V_{CODE}$, assert `settled`.
  5. `EMERGENCY_RECOVERY`: Immediately force $V_{CODE} = 5'd31$ ($1.50\text{ V}$), assert `timing_hazard`, hold for safe reset period.
- **Hysteresis Band**: A 1-tap deadband prevents continuous 1-LSB hunting/dithering on the analog rail.

---

## 4. Multi-Domain & Level-Shifter Strategy

The macro contains two distinct power domains:
1. **$V_{DD,1V8}$ (1.8V Static Domain)**: BGR, DAC, LDO Error Amplifier, AVS Controller FSM, I/O buffers.
2. **$V_{DD,CORE}$ (0.9V - 1.5V Dynamic Scaled Domain)**: Pipelined MAC digital load, Critical Path Monitor delay line.

### Domain Crossing Rules:
- Signals traversing from $V_{DD,CORE} \rightarrow V_{DD,1V8}$ (e.g., CPM margin signals) pass through **Low-to-High Level Shifters** (`sky130_fd_sc_hd__lpflow_lsbuf_lh_*`) and a 2-stage synchronizer to eliminate metastability.
- Signals traversing from $V_{DD,1V8} \rightarrow V_{DD,CORE}$ (e.g., MAC operand inputs) pass through **High-to-Low Level Shifters** (`sky130_fd_sc_hd__lpflow_lsbuf_hl_*`).
