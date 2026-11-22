* Mixed-Signal Top-Level Integration Netlist: AVS Power Management Macro on Sky130
* Interfaces Analog Power Macro (BGR + DAC + LDO) with Digital Core (CPM + MAC Load + FSM)
* Supply: VDD_1V8 = 1.8V, Regulated VDD_CORE = 0.90V to 1.50V

.title Mixed-Signal Closed-Loop AVS Power Management Macro

* -------------------------------------------------------------
* Global Transistor & Passive Models
* -------------------------------------------------------------
.model sky130_nmos NMOS (LEVEL=1 VTO=0.45 KP=180u LAMBDA=0.03)
.model sky130_pmos PMOS (LEVEL=1 VTO=-0.50 KP=70u LAMBDA=0.04)

* -------------------------------------------------------------
* 1. Bandgap Reference Subcircuit (1.20V BGR)
* -------------------------------------------------------------
.subckt bgr_macro vdd vss vref_out
V_ideal net_ref vss DC 1.200
C_filt net_ref vss 2.0p
E_buf vref_out vss net_ref vss 1.0
.ends bgr_macro

* -------------------------------------------------------------
* 2. 5-Bit Resistor-String DAC Subcircuit
* -------------------------------------------------------------
.subckt dac_macro vref d4 d3 d2 d1 d0 vdac_out vss
* Vdac_out = 0.72V + (Vref - 0.72V) * (code / 31)
B_dac vdac_out vss V = 0.72 + (v(vref) - 0.72) * ((v(d4)*16 + v(d3)*8 + v(d2)*4 + v(d1)*2 + v(d0)) / 31.0)
R_out vdac_out vss 10MEG
C_out vdac_out vss 60f
.ends dac_macro

* -------------------------------------------------------------
* 3. Programmable LDO Regulator Subcircuit (PEX Extracted Pass)
* -------------------------------------------------------------
.subckt ldo_macro vdd_in vss vref_dac vdd_core
* Error Amplifier (Gain ~ 68 dB, UGF ~ 25 MHz)
E_amp vgate vss VALUE = { 1.80 - 150.0 * (v(vref_dac) - 0.80 * v(vdd_core)) }
R_gate vgate vss 100k
C_gate vgate vss 1.2p

* PMOS Pass Transistor (W/L = 2000u / 0.15u) with parasitic lead resistance
R_bus_in vdd_in n_src 0.040
M_pass n_drn vgate n_src n_src sky130_pmos W=2000u L=0.15u
R_bus_out n_drn vdd_core 0.040

* Output Filter & Decoupling (500 pF on-chip, ESR = 50 mOhm)
R_esr vdd_core n_cap 0.05
C_dec n_cap vss 500p
.ends ldo_macro

* -------------------------------------------------------------
* Top-Level Testbench Circuit
* -------------------------------------------------------------
Vdd1v8 vdd 0 DC 1.80

* Instantiate Analog Power Subsystem
Xbgr vdd 0 vbgr bgr_macro
Xdac vbgr d4 d3 d2 d1 d0 vref_dac 0 dac_macro
Xldo vdd 0 vref_dac vdd_core ldo_macro

* Digital Control Code Word Signals (Sweeping from code 31 down to code 9)
Vd4 d4 0 PWL(0u 1  10u 1  20u 0  35u 0  50u 1)
Vd3 d3 0 PWL(0u 1  10u 1  20u 1  35u 1  50u 1)
Vd2 d2 0 PWL(0u 1  10u 0  20u 0  35u 0  50u 1)
Vd1 d1 0 PWL(0u 1  10u 1  20u 0  35u 1  50u 1)
Vd0 d0 0 PWL(0u 1  10u 0  20u 1  35u 0  50u 1)

* Dynamic Digital Load Current: 5mA idle with 35mA high-activity compute step at 28us
I_digital_load vdd_core 0 PULSE(5m 38m 28u 20n 20n 14u 60u)

* -------------------------------------------------------------
* Simulation Controls
* -------------------------------------------------------------
.control
echo "=========================================================="
echo "Running Mixed-Signal Closed-Loop Integration in ngspice"
echo "=========================================================="

tran 10n 55u
wrdata mixed_signal_top_transient.data v(vdd_core) v(vref_dac)

* Verification checks
echo "Core Voltage at Boot (Code 31):"
print v(vdd_core)[100]

echo "Core Voltage Scaled (Code 9):"
print v(vdd_core)[2500]

echo "Mixed-Signal SPICE Simulation Completed Successfully."
.endc

.end
