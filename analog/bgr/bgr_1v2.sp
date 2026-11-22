* Sky130 Transistor-Level 1.20V Bandgap Voltage Reference (BGR)
* Generates low-tempco 1.200V precision reference for AVS Reference DAC
* Features:
* - Diode-connected substrate PNPs: Q1 (1X emitter) and Q2 (8X emitter)
* - PTAT core: Delta-Vbe = (kT/q)*ln(8) across R1 (9.0 kOhm)
* - CTAT core: Vbe of Q1 (~0.642V @ 27C)
* - Summing output branch: R2 (79.5 kOhm) + Q3 (1X emitter) generating 1.200V
* - PMOS input OTA error amplifier forcing V(va) == V(vb) with wide common-mode range
* - Self-extinguishing active startup circuit preventing zero-current metastable lockup
* - Transistor-level unity-gain output buffer driving DAC resistor ladder

.title Sky130 Transistor-Level 1.20V Bandgap Reference

* Global Transistor & Diode Models (Sky130 parameters)
.model sky130_nmos NMOS (LEVEL=1 VTO=0.45 KP=180u LAMBDA=0.03 CJ=0.0008 CJSW=0.0003)
.model sky130_pmos PMOS (LEVEL=1 VTO=-0.50 KP=70u LAMBDA=0.04 CJ=0.0009 CJSW=0.0003)
.model D_PNP_1X D (IS=1e-16 RS=10 N=1.0)
.model D_PNP_8X D (IS=8e-16 RS=1.25 N=1.0)

* -------------------------------------------------------------
* BGR Core Subcircuit
* -------------------------------------------------------------
.subckt bgr_core vdd vss vref_out vbg_enable
* PMOS Current Mirror Pair (M1, M2)
Mp1 va pbias vdd vdd sky130_pmos W=15u L=1.0u
Mp2 vb pbias vdd vdd sky130_pmos W=15u L=1.0u

* PMOS Output Current Branch (M3)
Mp3 vref_int pbias vdd vdd sky130_pmos W=15u L=1.0u

* Core BJT / Diode branches
D1 va vss D_PNP_1X
R1 vb vq2 9.0k
D2 vq2 vss D_PNP_8X

* Output branch: Summing resistor R2 + Diode D3 for 1.200V output
R2 vref_int vq3 79.5k
D3 vq3 vss D_PNP_1X
Cfilter vref_int vss 2p

* PMOS Differential Input OTA Error Amplifier
Mtail v_tail pbias_ota vdd vdd sky130_pmos W=16u L=1.0u
Rbias_ota pbias_ota vss 80k
Mbias_ota pbias_ota pbias_ota vdd vdd sky130_pmos W=16u L=1.0u

Md1 n1 vb v_tail vdd sky130_pmos W=12u L=0.5u
Md2 pbias va v_tail vdd sky130_pmos W=12u L=0.5u

Mn1 n1 n1 vss vss sky130_nmos W=8u L=1.0u
Mn2 pbias n1 vss vss sky130_nmos W=8u L=1.0u
Cc pbias vss 5p

* Self-Extinguishing Startup Circuit
Rst_pull vdd n_st 1MEG
Mst_det n_st va vss vss sky130_nmos W=4u L=0.5u
Mst_inj pbias n_st vss vss sky130_nmos W=1u L=2.0u

* Transistor-Level Unity-Gain Output Buffer (Drives DAC resistor ladder)
M_buf1 n_buf1 vref_out tail_buf vss sky130_nmos W=12u L=0.5u
M_buf2 n_buf2 vref_int tail_buf vss sky130_nmos W=12u L=0.5u
Mtail_buf tail_buf nbias_buf vss vss sky130_nmos W=8u L=1.0u
Rbias_buf vdd nbias_buf 80k
Mbias_buf nbias_buf nbias_buf vss vss sky130_nmos W=8u L=1.0u
M_bufl1 n_buf1 n_buf1 vdd vdd sky130_pmos W=15u L=1.0u
M_bufl2 n_buf2 n_buf1 vdd vdd sky130_pmos W=15u L=1.0u
M_bufdrv vref_out n_buf2 vdd vdd sky130_pmos W=30u L=0.5u
M_bufsnk vref_out nbias_buf vss vss sky130_nmos W=12u L=1.0u
C_bufcomp n_buf2 vref_out 5p
.ends bgr_core

* -------------------------------------------------------------
* Testbench: Supply Sensitivity & Temperature Characterization
* -------------------------------------------------------------
Vdd vdd 0 DC 1.80
Ven en 0 DC 1.80

Xbgr vdd 0 vref en bgr_core

* Load with 38.75k DAC resistor ladder
Rdac_load vref 0 38.75k

.control
echo "=========================================================="
echo "Running Sky130 Transistor-Level 1.20V BGR Simulation"
echo "=========================================================="

* 1. Operating Point at 27C
op
echo "Nominal 27C Operating Voltages:"
print v(vref)

* 2. DC Supply Sweep (1.60V to 2.00V) -> Line Regulation
dc Vdd 1.6 2.0 0.05
wrdata bgr_line_reg.data v(vref)
echo "Line Regulation at 1.6V, 1.8V, 2.0V:"
print v(vref)[0] v(vref)[4] v(vref)[8]

* 3. Temperature Sweep (-40C to +125C) -> Temperature Coefficient
dc temp -40 125 5
wrdata bgr_temp_sweep.data v(vref)
echo "Temperature Drift at -40C, +25C, +125C:"
print v(vref)[0] v(vref)[13] v(vref)[33]

* 4. Transient Verification
tran 10n 40u
echo "Transient Reference at 10us and 40us:"
print v(vref)[1000] v(vref)[4000]

echo "Transistor-Level BGR Characterization Complete."
.endc

.end
