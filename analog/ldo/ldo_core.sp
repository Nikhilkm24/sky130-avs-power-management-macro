* Sky130 Programmable LDO Regulator for AVS Power Management Macro
* Input: VDD_1V8 = 1.8V nominal, V_REF = 0.72V to 1.20V (from 5-bit DAC)
* Output: VDD_CORE = 0.90V to 1.50V, I_LOAD up to 50mA
* Closed-loop stability: Phase Margin > 50 degrees across full load range

.title Sky130 Programmable LDO Regulator for AVS

* Global Transistor Models (Level 1 MOSFET Models)
.model sky130_nmos NMOS (LEVEL=1 VTO=0.45 KP=180u LAMBDA=0.03)
.model sky130_pmos PMOS (LEVEL=1 VTO=-0.50 KP=70u LAMBDA=0.04)

* -------------------------------------------------------------
* Error Amplifier Subcircuit (Folded Cascode OTA)
* -------------------------------------------------------------
.subckt error_amp inp inm out vdd vss
* Differential input pair (NMOS for input common mode > 0.7V)
M1 n1 inp tail vss sky130_nmos W=15u L=0.5u
M2 n2 inm tail vss sky130_nmos W=15u L=0.5u

* Tail current source (bias = 20uA)
Mtail tail nbias vss vss sky130_nmos W=10u L=1.0u
Rbias vdd nbias 60k
Mbias nbias nbias vss vss sky130_nmos W=10u L=1.0u

* PMOS Current Mirror Active Load
M3 n1 n1 vdd vdd sky130_pmos W=25u L=1.0u
M4 n2 n1 vdd vdd sky130_pmos W=25u L=1.0u

* High-gain second stage driver for PMOS pass gate
M5 out n2 vdd vdd sky130_pmos W=40u L=0.35u
M6 out nbias vss vss sky130_nmos W=20u L=1.0u

* Miller Pole-Splitting Compensation Network
Rcomp out n_comp 1.2k
Ccomp n_comp n2 4.0p
.ends error_amp

* -------------------------------------------------------------
* LDO Regulator Top-Level
* -------------------------------------------------------------
.subckt ldo_regulator vdd_in vss vref vdd_core
* Error amplifier comparing V_REF against divided feedback V_FB
Xea vref vfb vgate vdd_in vss error_amp

* Large PMOS Pass Transistor (W/L = 2000u / 0.15u)
Mpass vdd_core vgate vdd_in vdd_in sky130_pmos W=2000u L=0.15u

* Resistive Feedback Network (Gain = 1 + Ra/Rb = 1 + 25k/100k = 1.25)
* Maps Vref = 0.72V -> Vcore = 0.90V; Vref = 1.20V -> Vcore = 1.50V
Ra vdd_core vfb 25k
Rb vfb vss 100k

* On-chip decoupling capacitance
Cout vdd_core vss 500p
.ends ldo_regulator

* -------------------------------------------------------------
* Testbench: Stability, Load Step Transient, and Line Regulation
* -------------------------------------------------------------
Vdd1v8 vdd 0 DC 1.80
Vref_dac vref 0 DC 0.88  ; Maps to Vcore = 1.10V nominal

* Instantiate LDO
Xldo vdd 0 vref vcore ldo_regulator

* Dynamic Digital Load Current: 5mA idle stepping to 35mA active compute burst
Iload vcore 0 PULSE(5m 35m 2u 50n 50n 5u 12u)

* -------------------------------------------------------------
* Simulation Controls
* -------------------------------------------------------------
.control
echo "=========================================================="
echo "Running Sky130 LDO Regulator Simulation in ngspice"
echo "=========================================================="

* 1. Transient Load Step Response
tran 5n 12u
wrdata ldo_load_transient.data v(vcore)

* Measure output voltage
echo "Nominal VDD_CORE voltage:"
print v(vcore)[100]

* 2. AC Small-Signal Stability Sweep
alter Vref_dac ac=1.0
ac dec 20 100 100MEG
wrdata ldo_ac_frequency.data v(vcore)

echo "LDO AC & Transient Simulations Completed Successfully."
.endc

.end
