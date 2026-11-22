# System Specifications: Closed-Loop Adaptive Voltage Scaling (AVS) Macro on Sky130

## 1. Overview
Adaptive Voltage Scaling (AVS) is a real-time, closed-loop power management technique that dynamically minimizes the supply voltage ($V_{DD,CORE}$) delivered to a high-speed digital datapath. Unlike static worst-case sign-off (which must budget for worst-case Process, Voltage, Temperature variations, and On-Chip Variation / aging), AVS monitors the instantaneous silicon propagation delay using an in-situ **Critical Path Monitor (CPM)**. An **AVS Controller FSM** closes the loop with an on-chip **Programmable LDO Regulator** driven by a **5-bit Resistor-String DAC** and a **1.20 V Bandgap Reference (BGR)**.

---

## 2. Key Electrical Specifications

| Parameter | Symbol | Min | Typ | Max | Units | Condition / Comment |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Input Supply Voltage** | $V_{DD,IO}$ / $V_{IN}$ | 1.62 | 1.80 | 1.98 | V | Standard Sky130 1.8V analog supply |
| **Regulated Core Supply** | $V_{DD,CORE}$ | 0.90 | 1.10 | 1.50 | V | Dynamic voltage domain for digital load & CPM |
| **Ground Reference** | $V_{SS}$ | 0.0 | 0.0 | 0.0 | V | Common system ground |
| **Core Clock Frequency** | $F_{CORE}$ | 50 | 75 | 100 | MHz | Nominal operating clock for load datapath |
| **Controller Clock Frequency**| $F_{CTRL}$ | 10 | 12.5 | 25 | MHz | AVS FSM sampling and update clock |
| **Bandgap Voltage** | $V_{BGR}$ | 1.190 | 1.200 | 1.210 | V | $-40^\circ\text{C}$ to $125^\circ\text{C}$ cross-PVT |
| **BGR TempCo** | $TC_{BGR}$ | — | 18 | 25 | ppm/$^\circ$C | Across military temp range |
| **DAC Resolution** | $N_{DAC}$ | — | 5 | 6 | bits | 32 discrete voltage steps |
| **DAC Step Size** | $\Delta V_{STEP}$ | — | 19.35 | 20.0 | mV | $(V_{MAX} - V_{MIN}) / (2^{N}-1)$ |
| **DAC Linearity** | INL / DNL | — | $\pm 0.25$ | $\pm 0.45$ | LSB | Monotonic across all codes |
| **LDO Max Load Current** | $I_{LOAD,MAX}$ | — | 25 | 50 | mA | Pipelined MAC under 100% switching activity |
| **LDO Quiescent Current** | $I_Q$ | — | 65 | 95 | $\mu$A | Analog error amplifier + feedback bias |
| **LDO Dropout Voltage** | $V_{DO}$ | — | 140 | 200 | mV | At $I_{LOAD} = 50\text{ mA}, V_{OUT} = 1.5\text{ V}$ |
| **LDO Phase Margin** | $\phi_M$ | 52 | 60 | 72 | deg | Loop stability from $100\ \mu\text{A}$ to $50\text{ mA}$ load |
| **LDO PSRR @ 100 kHz** | $PSRR$ | 42 | 48 | — | dB | Measured at $V_{DD,IO} = 1.8\text{ V}$ |
| **LDO Output Ripple** | $V_{RIP}$ | — | $< 5$ | 12 | mV | Closed-loop steady-state |
| **CPM Taps** | $N_{TAPS}$ | — | 8 | 16 | taps | Buffer delay chain with thermometer flops |
| **Nominal Target Margin** | $M_{TGT}$ | 2 | 2 | 3 | taps | Hysteresis target guard-band window |
| **AVS Response Time** | $t_{RESP}$ | — | 5 | 15 | $\mu$s | Time to adapt from 1.5V down to optimum voltage |
| **Emergency Fallback Delay**| $t_{SAFE}$ | — | 1 | 2 | clock cycles | Instantaneous jump to $V_{MAX}$ on timing hazard |
| **Energy Savings** | $\eta_{SAVING}$ | 35 | 45 | 55 | % | vs. fixed worst-case signoff voltage ($1.50\text{ V}$) |

---

## 3. Power and Energy Formulations

### 3.1 Dynamic Power Dissipation
The dynamic switching power in the digital core is governed by:
$$P_{dyn} = \alpha \cdot C_L \cdot V_{DD,CORE}^2 \cdot f_{clk}$$
where:
- $\alpha$: Switching activity factor ($0.05 \le \alpha \le 0.85$).
- $C_L$: Total switched capacitance of the digital load.
- $V_{DD,CORE}$: Dynamic core voltage ($0.9\text{ V} \le V_{DD} \le 1.5\text{ V}$).
- $f_{clk}$: Digital clock frequency.

### 3.2 Leakage Power Dissipation
The static leakage power consists of subthreshold leakage and gate tunneling:
$$P_{leak} = V_{DD,CORE} \cdot I_{leak0} \cdot e^{\frac{V_{DD,CORE} - V_{TH}}{n \cdot V_T}}$$
As $V_{DD,CORE}$ scales down, leakage power drops exponentially due to Drain-Induced Barrier Lowering (DIBL) mitigation.

### 3.3 Energy Per Operation
$$E_{op} = \frac{P_{total}}{f_{clk}} = \alpha \cdot C_L \cdot V_{DD,CORE}^2 + \frac{V_{DD,CORE} \cdot I_{leak}}{f_{clk}}$$
When scaling $V_{DD,CORE}$ from a fixed worst-case $1.50\text{ V}$ down to an adaptive $1.05\text{ V}$ at nominal room temperature:
$$\text{Dynamic Energy Saving} = 1 - \left(\frac{1.05}{1.50}\right)^2 = 1 - 0.49 = 51.0\%$$
This represents a halving of power consumption while retaining guaranteed timing closure.

---

## 4. Signal Interface Definitions

### 4.1 System-Level Pinout
| Pin Name | Direction | Domain | Width | Description |
| :--- | :--- | :--- | :--- | :--- |
| `clk_io` | Input | VDD_1V8 | 1 | 1.8V system clock input (10-25 MHz) |
| `clk_core` | Input | VDD_CORE | 1 | High-speed core clock input (50-100 MHz) |
| `rst_n` | Input | VDD_1V8 | 1 | Active-low global asynchronous reset |
| `avs_enable` | Input | VDD_1V8 | 1 | 1 = Enable closed-loop AVS tracking, 0 = Manual override |
| `manual_code` | Input | VDD_1V8 | 5 | Manual DAC voltage code when `avs_enable` = 0 |
| `target_margin` | Input | VDD_1V8 | 4 | Desired tap margin code (default = 4'b0010, 2 taps) |
| `vdd_1v8` | Power | VDD_1V8 | — | 1.8V analog and I/O power rail |
| `vdd_core` | Power | VDD_CORE | — | Regulated 0.9–1.5V core power rail output from LDO |
| `vss` | Ground | Ground | — | Global 0V reference |
| `v_code` | Output (internal) | VDD_1V8 | 5 | Output of AVS FSM to Reference DAC |
| `margin_code` | Input (internal) | VDD_1V8 | 4 | Synchronized thermometer margin code from CPM |
| `timing_hazard`| Output | VDD_1V8 | 1 | Asserted if margin drops to zero (emergency fallback) |
| `settled` | Output | VDD_1V8 | 1 | Asserted when AVS loop is locked inside target window |
| `data_in` | Input | VDD_CORE | 16 | Operand input to pipelined MAC load |
| `mac_accum_out`| Output | VDD_CORE | 32 | Output of pipelined MAC load |
