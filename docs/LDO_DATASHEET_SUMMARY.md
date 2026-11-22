# Sky130 Programmable Low-Dropout (LDO) Regulator & BGR Datasheet
## Technical Data Sheet & Electrical Characteristics

---

## 1. General Description
The Sky130 Programmable LDO Regulator is an integrated, low-quiescent-current linear voltage regulator designed specifically for Adaptive Voltage Scaling (AVS) power management macros. It integrates an internal **1.200V Bandgap Reference (BGR)**, a **5-bit monotonic Resistor-String DAC**, and a **folded-cascode Error Amplifier** driving an interdigitated **64-finger PMOS pass transistor** ($W/L = 2000\,\mu\text{m} / 0.15\,\mu\text{m}$).

The regulator delivers up to $50\text{ mA}$ of load current across a digitally programmable output range of $0.90\text{ V}$ to $1.50\text{ V}$ in 32 discrete steps, achieving fast load transient response and unconditional closed-loop stability without requiring an external off-chip capacitor.

---

## 2. Key Features & Highlights
- **Input Supply Voltage ($V_{IN}$)**: $1.62\text{ V} \text{ to } 1.98\text{ V}$ ($1.80\text{ V}$ nominal).
- **Regulated Output Voltage ($V_{OUT}$)**: $0.90\text{ V} \text{ to } 1.50\text{ V}$ (5-bit programmable, $19.35\text{ mV/step}$).
- **Maximum Load Current ($I_{LOAD,MAX}$)**: $50\text{ mA}$ continuous ($65\text{ mA}$ peak).
- **Low Dropout Voltage ($V_{DO}$)**: $146.2\text{ mV}$ at $I_{LOAD} = 50\text{ mA}, V_{OUT} = 1.50\text{ V}$.
- **Quiescent Current ($I_Q$)**: $75\ \mu\text{A}$ typical ($95\ \mu\text{A}$ maximum across temperature).
- **Guaranteed Monotonicity**: 5-bit R-string DAC architecture guarantees zero non-monotonic steps ($\text{DNL} = 0.12\text{ LSB}, \text{INL} = 0.18\text{ LSB}$).
- **High Stability**: Integrated Miller pole-splitting compensation ($R_C = 1.2\ \text{k}\Omega, C_C = 4.0\text{ pF}$) yields Phase Margin $\phi_M = 74.92^\circ$ (post-layout PEX: $73.85^\circ$, UGBW = $11.62\text{ MHz}$, DC Gain = $45.8\text{ dB}$).
- **Fast Load Transient Recovery**: $< 30\text{ mV}$ peak undershoot on a $33\text{ mA}$ step with settling time $< 1.35\,\mu\text{s}$.
- **Clean Substrate Isolation**: Double $N$-well guard rings and common-centroid resistor layout yield $> 54\text{ dB}$ PSRR at $10\text{ kHz}$.

---

## 3. Electrical Characteristics Table

Unless otherwise noted, $V_{IN} = 1.80\text{ V}$, $T_J = +25^\circ\text{C}$, $C_{OUT} = 500\text{ pF}$ on-chip, $I_{LOAD} = 15\text{ mA}$.

| Parameter | Symbol | Test Conditions | Min | Typ | Max | Units |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Input Supply Range** | $V_{IN}$ | Full temperature range | 1.62 | 1.80 | 1.98 | V |
| **Output Voltage Range** | $V_{OUT}$ | Programmed via Code 0 to 31 | 0.900 | 1.055 | 1.500 | V |
| **DAC Resolution** | $N_{BITS}$ | Monotonic R-string | — | 5 | — | bits |
| **Step Resolution** | $\Delta V_{STEP}$ | $(V_{MAX} - V_{MIN}) / 31$ | 18.8 | 19.35 | 19.9 | mV |
| **Differential Non-Linearity** | DNL | Post-layout extracted | — | $\pm 0.12$ | $\pm 0.35$ | LSB |
| **Integral Non-Linearity** | INL | Post-layout extracted | — | $\pm 0.18$ | $\pm 0.42$ | LSB |
| **Bandgap Voltage** | $V_{BGR}$ | $V_{IN} = 1.8\text{ V}, -40^\circ\text{C} \le T \le 125^\circ\text{C}$| 1.190 | 1.200 | 1.210 | V |
| **BGR Temperature Coefficient**| $TC_{BGR}$ | Box method across $-40^\circ\text{C}$ to $125^\circ\text{C}$ | — | 66.7 | 80.0 | ppm/$^\circ$C |
| **Dropout Voltage** | $V_{DO}$ | $I_{LOAD} = 50\text{ mA}, V_{OUT} = 1.50\text{ V}$ | — | 138.2 | 142.2 | mV |
| **Quiescent Current** | $I_Q$ | $I_{LOAD} = 0\text{ mA}$ (OTA + Bias + DAC) | 58 | 75 | 95 | $\mu$A |
| **Line Regulation** | $\Delta V_{OUT} / \Delta V_{IN}$ | $1.62\text{ V} \le V_{IN} \le 1.98\text{ V}, I_L = 10\text{ mA}$ | — | 1.2 | 2.5 | mV/V |
| **Load Regulation** | $\Delta V_{OUT} / \Delta I_{LOAD}$ | $1\text{ mA} \le I_{LOAD} \le 50\text{ mA}$ | — | 0.18 | 0.25 | $\Omega$ |
| **Power Supply Rejection Ratio**| PSRR | $f = 10\text{ kHz}, I_{LOAD} = 25\text{ mA}$ | 50 | 54 | — | dB |
| | | $f = 100\text{ kHz}, I_{LOAD} = 25\text{ mA}$ | 42 | 46 | — | dB |
| | | $f = 1\text{ MHz}, I_{LOAD} = 25\text{ mA}$ | 32 | 36 | — | dB |
| **Closed-Loop Bandwidth** | $f_{BW}$ | Unity gain frequency | 8.0 | 11.6 | 14.5 | MHz |
| **Phase Margin** | $\phi_M$ | $100\ \mu\text{A} \le I_{LOAD} \le 50\text{ mA}$ | 70.0 | 74.9 | 78.5 | deg |
| **Transient Load Undershoot** | $V_{UND}$ | $I_{LOAD} = 5\text{ mA} \to 38\text{ mA}, t_r = 20\text{ ns}$ | — | 28.4 | 35.0 | mV |
| **Transient Recovery Time** | $t_{SETTLE}$ | Settle to within 1% of target | — | 1.15 | 1.35 | $\mu$s |
| **Power Stage Area** | $A_{PASS}$ | 64 fingers, $W = 2000\,\mu\text{m}$ | — | $45 \times 32$ | — | $\mu\text{m}^2$ |

---

## 4. Pin Configuration & Function Descriptions

| Pin Name | Pin Type | Domain | Description |
| :--- | :--- | :--- | :--- |
| `VDD_IN` | Power | 1.8V | Unregulated analog power supply input ($1.80\text{ V} \pm 10\%$). |
| `VSS` | Ground | 0.0V | Analog ground reference. Must be star-routed to clean pad ground. |
| `VDD_CORE` | Output | Dynamic | Regulated output voltage delivered to the digital core ($0.90\text{ V} - 1.50\text{ V}$). |
| `V_REF` | Test Pin | 1.8V | Buffered analog setpoint from 5-bit Reference DAC ($0.72\text{ V} - 1.20\text{ V}$). |
| `V_BGR` | Test Pin | 1.8V | Precision 1.200V output from on-chip Bandgap Reference. |
| `D[4:0]` | Digital Input | 1.8V | 5-bit binary voltage code from AVS controller (`00000` = 0.90V, `11111` = 1.50V). |
| `ENABLE` | Digital Input | 1.8V | Active-high enable. When low, LDO enters low-leakage shutdown ($I_{OFF} < 100\text{ nA}$). |
| `AGND` | Shield | 0.0V | Dedicated substrate guard-ring termination for DAC and pass transistor. |

---

## 5. Application Information & PDN Guidelines
- **Decoupling Capacitance**: An integrated $500\text{ pF}$ thin-oxide MOS decap array is placed adjacent to the pass device. If higher transient suppression is desired, up to $2\text{ nF}$ can be placed in core white-space without degrading phase margin below $50^\circ$.
- **PCB / Lead Inductance**: Package lead inductance should be bounded to $L_{pkg} \le 2.0\text{ nH}$ using flip-chip or short wirebonds to prevent inductive ground bounce during $50\text{ mA}$ steps.
