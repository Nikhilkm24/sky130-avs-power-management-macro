# Interview Talking Points & Role-Specific Deep Dives

This project demonstrates cross-domain mastery across **all four core silicon engineering disciplines**:
1. **Static Timing Analysis (STA) & Timing Sign-Off**
2. **Physical Design (PD) & Multi-Voltage Implementation**
3. **Analog IC Design (Power Management & Data Converters)**
4. **Analog / Custom Layout & Physical Verification**

---

## 1. Static Timing Analysis (STA) Role

### Key Elevator Pitch:
> *"Unlike standard open-loop worst-case timing closure, I implemented in-situ closed-loop timing margin tracking on Sky130. I created a calibrated Critical Path Monitor that correlates directly with post-route timing reports and SPICE transient simulations, recovering over 45% in dynamic power dissipation."*

### Deep-Dive Interview Questions & Answers:

**Q1: How did you handle timing sign-off when Sky130 standard cells only provide Liberty files at fixed voltages (1.40V, 1.80V, 1.95V)?**
- *Answer*: "Sky130 open PDK natively characterizes standard cells only at discrete voltage points (`1.80V TT`, `1.95V FF`, `1.40V SS`). For our dynamic operating regime of $0.90\text{ V} - 1.50\text{ V}$, I developed a dual-path characterization strategy:
  1. I ran SPICE sweeps across fine voltage steps ($0.9\text{ V}$ to $1.5\text{ V}$ in $50\text{ mV}$ increments) for all constituent cell types of the critical path (XOR, FA, MUX, NAND, Inverters).
  2. I normalized the delay curves against OpenSTA runs at $1.40\text{ V}$ and $1.80\text{ V}$ to derive an empirical $\alpha$-power law delay model: $\tau_d \propto \frac{V_{DD}}{(V_{DD} - V_{TH})^\alpha}$.
  3. I calibrated the CPM tapped delay line so that tap 2 corresponds to the exact setup slack target required across all PVT corners."

**Q2: How did you constrain and analyze Clock Domain Crossing (CDC) between the 1.8V controller and the variable-voltage core?**
- *Answer*: "The controller runs at a slower sampling frequency ($F_{CTRL} = 12.5\text{ MHz}$) on $V_{DD,1V8}$, while the MAC core runs at $F_{CORE} = 75\text{ MHz}$ on $V_{DD,CORE}$.
  - The CPM output is a multi-bit thermometer code. Because multi-bit buses can suffer skew, the CPM samples the delay line on the core clock and latches it into a shadow register.
  - A valid pulse or double-flip-flop synchronizer brings the signal safely into the controller domain.
  - In the SDC, I specified `set_clock_groups -asynchronous` between `clk_io` and `clk_core`, and added `set_max_delay -datapath_only` across the synchronizer paths to prevent OpenSTA from inserting excessive buffer delay on the CDC path."

---

## 2. Physical Design (PD) Role

### Key Elevator Pitch:
> *"I structured a hierarchical multi-voltage floorplan on Sky130 with isolated power domains (VDD_1V8 and VDD_CORE), resolved level-shifter placement, and designed an electromigration-compliant power delivery network capable of supporting 50 mA transient load steps."*

### Deep-Dive Interview Questions & Answers:

**Q1: How do you handle multiple voltage domains in an open-source tool flow like OpenLane2 / OpenROAD?**
- *Answer*: "OpenLane/OpenROAD traditionally assumes a flat single-rail PDN. To implement true multi-voltage physical design:
  1. I partitioned the design hierarchically: the core digital load + CPM is hardened as a self-contained macro with dedicated `VDD_CORE` and `VSS` power pins.
  2. At the top level, the analog macro (LDO + DAC) and the AVS controller are placed in the `VDD_1V8` domain.
  3. Dedicated level-shifter cells (`sky130_fd_sc_hd__lpflow_lsbuf_*`) are placed along the macro interface boundary, connected to both power rails (`VPWR` and `VPB/VNB`).
  4. Top-level routing bridges the LDO power output directly to the macro power ring with wide Met4/Met5 straps."

**Q2: How did you analyze and mitigate IR drop in the variable-voltage core?**
- *Answer*: "Because dynamic power varies as $V_{DD}^2$, operating at lower voltage ($0.95\text{ V}$) makes the circuit much more sensitive to IR drop: a $50\text{ mV}$ drop at $1.8\text{ V}$ is under $3\%$, but at $0.95\text{ V}$ it is over $5.2\%$, causing severe delay degradation.
  - I created a dense dual-rail power mesh using Met4 (vertical) and Met5 (horizontal) with wide strap pitches.
  - The static and dynamic IR drop was bounded to $< 20\text{ mV}$ ($< 2\%$) using OpenROAD's PDN analyzer."

---

## 3. Analog IC Design Role

### Key Elevator Pitch:
> *"I designed a fully programmable Low-Dropout Regulator with a 5-bit resistor-string DAC and Bandgap Reference, achieving $> 55^\circ$ phase margin, $> 45\text{ dB}$ PSRR, and fast load transient recovery under dynamic digital switching."*

### Deep-Dive Interview Questions & Answers:

**Q1: How did you ensure stability of the LDO across wide load currents ($100\ \mu\text{A}$ to $50\text{ mA}$)?**
- *Answer*: "An LDO with a PMOS pass transistor is a two-gain-stage system whose output pole moves by orders of magnitude with load current:
  $$\omega_{p,out} = \frac{1}{(R_L \parallel r_{ds,pass}) \cdot C_{OUT}}$$
  - At minimum load ($100\ \mu\text{A}$), $R_L$ is very high, pushing the output pole to low frequencies.
  - At maximum load ($50\text{ mA}$), the output pole moves to high frequencies while the pass transistor transconductance $g_m$ increases, boosting the open-loop gain and pushing the unity-gain frequency (UGF) out.
  - I implemented Miller pole-splitting compensation with a series nulling resistor ($R_C = 1.2\ \text{k}\Omega, C_C = 4\text{ pF}$) across the error amplifier. This placed the dominant pole inside the amplifier while pushing the output pole beyond the UGF, ensuring Phase Margin $> 55^\circ$ across all load conditions."

**Q2: Why choose a Resistor-String DAC over a Current-Steering or R-2R DAC?**
- *Answer*: "In an AVS closed-loop power supply, **monotonicity is a non-negotiable safety requirement**. A non-monotonic step (where increasing the code decreases the voltage) could cause positive feedback in the control FSM, driving the loop into instability or timing failure. A resistor-string DAC is inherently monotonic by topology, requires zero calibration, and has negligible glitch energy."

---

## 4. Analog & Custom Layout Role

### Key Elevator Pitch:
> *"I designed the common-centroid layout for the 5-bit R-string DAC, sized and interdigitated the PMOS pass transistor for electromigration and thermal balance, and passed full DRC, LVS, and PEX in Sky130."*

### Deep-Dive Interview Questions & Answers:

**Q1: What layout techniques were used to ensure matching in the 5-bit R-string DAC?**
- *Answer*: "To achieve DNL and INL $< 0.4\text{ LSB}$:
  1. I used unit resistor cells ($500\ \Omega$) constructed from high-sheet-resistance polysilicon (`res_high_po`).
  2. The 32 unit resistors were arranged in a 2D matrix ($4 \times 8$ or $8 \times 4$) with a common-centroid layout pattern to cancel linear process and thermal gradients across the die.
  3. Dummy resistors were placed on all four edges of the array to ensure uniform optical lithography and chemical-mechanical planarization (CMP) etch rates.
  4. Guard rings tied to clean analog ground isolate the resistor array from substrate noise generated by the high-speed digital core."

**Q2: How did you lay out the PMOS pass transistor for high-current electromigration (EM)?**
- *Answer*: "The PMOS pass device carries up to $50\text{ mA}$. A standard narrow transistor finger would suffer catastrophic electromigration:
  - The transistor was divided into 64 parallel interdigitated fingers with shared source and drain diffusions to minimize drain junction capacitance.
  - Wide top-level metals (Met4 and Met5) were used for both the input supply rail and regulated output rail, with dense via arrays to distribute the current evenly across all fingers without hot spots.
  - The metal widths were sized based on Sky130 EM design rules ($J_{max} \approx 1\text{ mA}/\mu\text{m}$ at $105^\circ\text{C}$)."
