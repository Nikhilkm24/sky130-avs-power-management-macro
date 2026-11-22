* Mixed-Signal Top-Level Integration Netlist: AVS Power Management Macro on Sky130
* Interfaces Transistor-Level Analog Power Macro (BGR + 32-R DAC + LDO) with Digital Core Load
* Supply: VDD_1V8 = 1.8V, Regulated VDD_CORE = 0.90V to 1.50V

.title Mixed-Signal Closed-Loop AVS Power Management Macro

* -------------------------------------------------------------
* Global Transistor & Diode Models (Sky130 parameters)
* -------------------------------------------------------------
.model sky130_nmos NMOS (LEVEL=1 VTO=0.45 KP=180u LAMBDA=0.03 CJ=0.0008 CJSW=0.0003)
.model sky130_pmos PMOS (LEVEL=1 VTO=-0.50 KP=70u LAMBDA=0.04 CJ=0.0009 CJSW=0.0003)
.model D_PNP_1X D (IS=1e-16 RS=10 N=1.0)
.model D_PNP_8X D (IS=8e-16 RS=1.25 N=1.0)

* -------------------------------------------------------------
* 1. Transistor-Level 1.20V Bandgap Reference Macro
* -------------------------------------------------------------
.subckt bgr_macro vdd vss vref_out
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
.ends bgr_macro

* -------------------------------------------------------------
* 2. Physical 32-Resistor String DAC Macro
* -------------------------------------------------------------
.subckt dac_macro vref d4 d3 d2 d1 d0 vout vss
* Bottom offset resistor setting tap0 to 0.720V
Rbot n0 vss 23.25k

* 31 Series Unit Resistors (500 Ohm each)
R0  n0  n1  500
R1  n1  n2  500
R2  n2  n3  500
R3  n3  n4  500
R4  n4  n5  500
R5  n5  n6  500
R6  n6  n7  500
R7  n7  n8  500
R8  n8  n9  500
R9  n9  n10 500
R10 n10 n11 500
R11 n11 n12 500
R12 n12 n13 500
R13 n13 n14 500
R14 n14 n15 500
R15 n15 n16 500
R16 n16 n17 500
R17 n17 n18 500
R18 n18 n19 500
R19 n19 n20 500
R20 n20 n21 500
R21 n21 n22 500
R22 n22 n23 500
R23 n23 n24 500
R24 n24 n25 500
R25 n25 n26 500
R26 n26 n27 500
R27 n27 n28 500
R28 n28 n29 500
R29 n29 n30 500
R30 n30 n31 500
Rtop vref n31 1m

* 32 Selection Switches
Msw0  vout s0  n0  vss sky130_nmos W=2u L=0.15u
Msw1  vout s1  n1  vss sky130_nmos W=2u L=0.15u
Msw2  vout s2  n2  vss sky130_nmos W=2u L=0.15u
Msw3  vout s3  n3  vss sky130_nmos W=2u L=0.15u
Msw4  vout s4  n4  vss sky130_nmos W=2u L=0.15u
Msw5  vout s5  n5  vss sky130_nmos W=2u L=0.15u
Msw6  vout s6  n6  vss sky130_nmos W=2u L=0.15u
Msw7  vout s7  n7  vss sky130_nmos W=2u L=0.15u
Msw8  vout s8  n8  vss sky130_nmos W=2u L=0.15u
Msw9  vout s9  n9  vss sky130_nmos W=2u L=0.15u
Msw10 vout s10 n10 vss sky130_nmos W=2u L=0.15u
Msw11 vout s11 n11 vss sky130_nmos W=2u L=0.15u
Msw12 vout s12 n12 vss sky130_nmos W=2u L=0.15u
Msw13 vout s13 n13 vss sky130_nmos W=2u L=0.15u
Msw14 vout s14 n14 vss sky130_nmos W=2u L=0.15u
Msw15 vout s15 n15 vss sky130_nmos W=2u L=0.15u
Msw16 vout s16 n16 vss sky130_nmos W=2u L=0.15u
Msw17 vout s17 n17 vss sky130_nmos W=2u L=0.15u
Msw18 vout s18 n18 vss sky130_nmos W=2u L=0.15u
Msw19 vout s19 n19 vss sky130_nmos W=2u L=0.15u
Msw20 vout s20 n20 vss sky130_nmos W=2u L=0.15u
Msw21 vout s21 n21 vss sky130_nmos W=2u L=0.15u
Msw22 vout s22 n22 vss sky130_nmos W=2u L=0.15u
Msw23 vout s23 n23 vss sky130_nmos W=2u L=0.15u
Msw24 vout s24 n24 vss sky130_nmos W=2u L=0.15u
Msw25 vout s25 n25 vss sky130_nmos W=2u L=0.15u
Msw26 vout s26 n26 vss sky130_nmos W=2u L=0.15u
Msw27 vout s27 n27 vss sky130_nmos W=2u L=0.15u
Msw28 vout s28 n28 vss sky130_nmos W=2u L=0.15u
Msw29 vout s29 n29 vss sky130_nmos W=2u L=0.15u
Msw30 vout s30 n30 vss sky130_nmos W=2u L=0.15u
Msw31 vout s31 n31 vss sky130_nmos W=2u L=0.15u

* Decoder Logic
.param vdd_hi=1.8
Bdec0  s0  vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 0)  < 0.5) ? vdd_hi : 0.0
Bdec1  s1  vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 1)  < 0.5) ? vdd_hi : 0.0
Bdec2  s2  vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 2)  < 0.5) ? vdd_hi : 0.0
Bdec3  s3  vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 3)  < 0.5) ? vdd_hi : 0.0
Bdec4  s4  vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 4)  < 0.5) ? vdd_hi : 0.0
Bdec5  s5  vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 5)  < 0.5) ? vdd_hi : 0.0
Bdec6  s6  vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 6)  < 0.5) ? vdd_hi : 0.0
Bdec7  s7  vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 7)  < 0.5) ? vdd_hi : 0.0
Bdec8  s8  vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 8)  < 0.5) ? vdd_hi : 0.0
Bdec9  s9  vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 9)  < 0.5) ? vdd_hi : 0.0
Bdec10 s10 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 10) < 0.5) ? vdd_hi : 0.0
Bdec11 s11 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 11) < 0.5) ? vdd_hi : 0.0
Bdec12 s12 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 12) < 0.5) ? vdd_hi : 0.0
Bdec13 s13 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 13) < 0.5) ? vdd_hi : 0.0
Bdec14 s14 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 14) < 0.5) ? vdd_hi : 0.0
Bdec15 s15 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 15) < 0.5) ? vdd_hi : 0.0
Bdec16 s16 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 16) < 0.5) ? vdd_hi : 0.0
Bdec17 s17 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 17) < 0.5) ? vdd_hi : 0.0
Bdec18 s18 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 18) < 0.5) ? vdd_hi : 0.0
Bdec19 s19 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 19) < 0.5) ? vdd_hi : 0.0
Bdec20 s20 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 20) < 0.5) ? vdd_hi : 0.0
Bdec21 s21 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 21) < 0.5) ? vdd_hi : 0.0
Bdec22 s22 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 22) < 0.5) ? vdd_hi : 0.0
Bdec23 s23 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 23) < 0.5) ? vdd_hi : 0.0
Bdec24 s24 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 24) < 0.5) ? vdd_hi : 0.0
Bdec25 s25 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 25) < 0.5) ? vdd_hi : 0.0
Bdec26 s26 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 26) < 0.5) ? vdd_hi : 0.0
Bdec27 s27 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 27) < 0.5) ? vdd_hi : 0.0
Bdec28 s28 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 28) < 0.5) ? vdd_hi : 0.0
Bdec29 s29 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 29) < 0.5) ? vdd_hi : 0.0
Bdec30 s30 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 30) < 0.5) ? vdd_hi : 0.0
Bdec31 s31 vss V = (abs((v(d4)*16+v(d3)*8+v(d2)*4+v(d1)*2+v(d0)) - 31) < 0.5) ? vdd_hi : 0.0

Rload vout vss 10MEG
Cout  vout vss 100f
.ends dac_macro

* -------------------------------------------------------------
* 3. Transistor-Level LDO Regulator Macro
* -------------------------------------------------------------
.subckt ldo_macro vdd_in vss vref vdd_core
* Error Amplifier
M1 n1 vref tail vss sky130_nmos W=20u L=0.5u
M2 n2 vfb  tail vss sky130_nmos W=20u L=0.5u
Mtail tail nbias vss vss sky130_nmos W=12u L=1.0u
Rbias vdd_in nbias 60k
Mbias nbias nbias vss vss sky130_nmos W=12u L=1.0u
M3 n1 n1 vdd_in vdd_in sky130_pmos W=30u L=1.0u
M4 n2 n1 vdd_in vdd_in sky130_pmos W=30u L=1.0u
M5 vgate n2 vdd_in vdd_in sky130_pmos W=40u L=0.5u
M6 vgate nbias vss vss sky130_nmos W=20u L=1.0u
Rcomp vgate n_comp 3.6k
Ccomp n_comp n2 22.0p

* Pass transistor
Mpass vdd_core vgate vdd_in vdd_in sky130_pmos W=2000u L=0.15u

* Feedback divider (Gain = 1 + 25k/100k = 1.25)
Ra vdd_core vfb 25k
Rb vfb vss 100k

* Decoupling cap with ESR
Resr vdd_core n_cout 0.30
Cout n_cout vss 1.5n
.ends ldo_macro

* -------------------------------------------------------------
* Top-Level Testbench Circuit
* -------------------------------------------------------------
Vdd1v8 vdd 0 DC 1.80

* Instantiate Full Analog Subsystem
Xbgr vdd 0 vbgr bgr_macro
Xdac vbgr d4 d3 d2 d1 d0 vref_dac 0 dac_macro
Xldo vdd 0 vref_dac vdd_core ldo_macro

* Digital Control Code Word Signals (Sweeping from code 31 down to code 8)
Vd4 d4 0 PWL(0u 1  12u 1  20u 0  35u 0  48u 0)
Vd3 d3 0 PWL(0u 1  12u 1  20u 1  35u 1  48u 1)
Vd2 d2 0 PWL(0u 1  12u 0  20u 0  35u 0  48u 0)
Vd1 d1 0 PWL(0u 1  12u 1  20u 0  35u 0  48u 0)
Vd0 d0 0 PWL(0u 1  12u 0  20u 0  35u 0  48u 0)

* Dynamic Digital Load Current: 5mA idle with 33mA high-activity compute step at 24us
I_digital_load vdd_core 0 PULSE(5m 38m 24u 20n 20n 14u 60u)

* -------------------------------------------------------------
* Simulation Controls
* -------------------------------------------------------------
.control
echo "=========================================================="
echo "Running Transistor-Level Mixed-Signal Integration in ngspice"
echo "=========================================================="

tran 10n 55u
let i_supply = -vdd1v8#branch
let p_supply = 1.80 * i_supply
wrdata mixed_signal_top_transient.data v(vdd_core) v(vref_dac) v(vbgr) i_supply p_supply

echo "BGR Reference Voltage:"
print v(vbgr)[100]
echo "Core Voltage at Boot (Code 31):"
print v(vdd_core)[100]
echo "Core Voltage Scaled (Code 8):"
print v(vdd_core)[3000]

echo "Transistor-Level Mixed-Signal Simulation Completed Successfully."
.endc

.end
