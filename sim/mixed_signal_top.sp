* Mixed-Signal Top-Level Integration Netlist: AVS Power Management Macro on Sky130
* Interfaces Transistor-Level Analog Power Macro (BGR + 32-R DAC + LDO) with Digital Core Load
* Supply: VDD_1V8 = 1.8V, Regulated VDD_CORE = 0.90V to 1.50V
* Phase H: Full SkyWater 130nm BSIM4 Foundry Models over 100 us Multi-Phase Transient

.title Mixed-Signal Closed-Loop AVS Power Management Macro (BSIM4 Sign-Off)

* -------------------------------------------------------------
* Include SkyWater 130nm BSIM4 PDK Models
* -------------------------------------------------------------
.lib "../pdk_sky130A/libs.tech/ngspice/sky130.lib.spice" tt

* -------------------------------------------------------------
* 1. Transistor-Level 1.20V Bandgap Reference Macro (BSIM4)
* -------------------------------------------------------------
.subckt bgr_macro vdd vss vref_out
* PMOS Current Mirror Pair (M1, M2)
Xp1 va pbias vdd vdd sky130_fd_pr__pfet_01v8 w=15 l=1.0
Xp2 vb pbias vdd vdd sky130_fd_pr__pfet_01v8 w=15 l=1.0

* PMOS Output Current Branch (M3)
Xp3 vref_int pbias vdd vdd sky130_fd_pr__pfet_01v8 w=15 l=1.0

* Core BJT / Diode branches (Sky130 PNP substrate transistor: Collector Base Emitter)
Xpnp1 vss vss va  sky130_fd_pr__pnp_05v5_W3p40L3p40 m=1
R1 vb vq2 9.0k
Xpnp2 vss vss vq2 sky130_fd_pr__pnp_05v5_W3p40L3p40 m=8

* Output branch: Summing resistor R2 + Diode D3 for 1.200V output
R2 vref_int vq3 79.5k
Xpnp3 vss vss vq3 sky130_fd_pr__pnp_05v5_W3p40L3p40 m=1
Cfilter vref_int vss 2p

* PMOS Differential Input OTA Error Amplifier
Xtail v_tail pbias_ota vdd vdd sky130_fd_pr__pfet_01v8 w=16 l=1.0
Rbias_ota pbias_ota vss 80k
Xbias_ota pbias_ota pbias_ota vdd vdd sky130_fd_pr__pfet_01v8 w=16 l=1.0

Xd1 n1 vb v_tail vdd sky130_fd_pr__pfet_01v8 w=12 l=0.5
Xd2 pbias va v_tail vdd sky130_fd_pr__pfet_01v8 w=12 l=0.5

Xn1 n1 n1 vss vss sky130_fd_pr__nfet_01v8 w=8 l=1.0
Xn2 pbias n1 vss vss sky130_fd_pr__nfet_01v8 w=8 l=1.0
Cc pbias vss 5p

* Self-Extinguishing Startup Circuit
Rst_pull vdd n_st 1MEG
Xst_det n_st va vss vss sky130_fd_pr__nfet_01v8 w=4 l=0.5
Xst_inj pbias n_st vss vss sky130_fd_pr__nfet_01v8 w=1 l=2.0

* Transistor-Level Unity-Gain Output Buffer (Drives DAC resistor ladder)
X_buf1 n_buf1 vref_out tail_buf vss sky130_fd_pr__nfet_01v8 w=12 l=0.5
X_buf2 n_buf2 vref_int tail_buf vss sky130_fd_pr__nfet_01v8 w=12 l=0.5
Xtail_buf tail_buf nbias_buf vss vss sky130_fd_pr__nfet_01v8 w=8 l=1.0
Rbias_buf vdd nbias_buf 80k
Xbias_buf nbias_buf nbias_buf vss vss sky130_fd_pr__nfet_01v8 w=8 l=1.0
X_bufl1 n_buf1 n_buf1 vdd vdd sky130_fd_pr__pfet_01v8 w=15 l=1.0
X_bufl2 n_buf2 n_buf1 vdd vdd sky130_fd_pr__pfet_01v8 w=15 l=1.0
X_bufdrv vref_out n_buf2 vdd vdd sky130_fd_pr__pfet_01v8 w=30 l=0.5
X_bufsnk vref_out nbias_buf vss vss sky130_fd_pr__nfet_01v8 w=12 l=1.0
C_bufcomp n_buf2 vref_out 5p
.ends bgr_macro

* -------------------------------------------------------------
* 2. Physical 32-Resistor String DAC Macro (BSIM4)
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

* 32 NMOS Selection Switches (BSIM4 sky130_fd_pr__nfet_01v8, W=2u, L=0.15u)
Xsw0  vout s0  n0  vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw1  vout s1  n1  vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw2  vout s2  n2  vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw3  vout s3  n3  vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw4  vout s4  n4  vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw5  vout s5  n5  vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw6  vout s6  n6  vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw7  vout s7  n7  vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw8  vout s8  n8  vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw9  vout s9  n9  vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw10 vout s10 n10 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw11 vout s11 n11 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw12 vout s12 n12 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw13 vout s13 n13 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw14 vout s14 n14 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw15 vout s15 n15 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw16 vout s16 n16 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw17 vout s17 n17 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw18 vout s18 n18 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw19 vout s19 n19 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw20 vout s20 n20 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw21 vout s21 n21 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw22 vout s22 n22 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw23 vout s23 n23 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw24 vout s24 n24 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw25 vout s25 n25 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw26 vout s26 n26 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw27 vout s27 n27 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw28 vout s28 n28 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw29 vout s29 n29 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw30 vout s30 n30 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15
Xsw31 vout s31 n31 vss sky130_fd_pr__nfet_01v8 w=2 l=0.15

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
* 3. Transistor-Level LDO Regulator Macro (BSIM4)
* -------------------------------------------------------------
.subckt ldo_macro vdd_in vss vref vdd_core
* Error Amplifier Differential Pair & Current Mirrors
X1 n1 vref tail vss sky130_fd_pr__nfet_01v8 w=20 l=0.5
X2 n2 vfb  tail vss sky130_fd_pr__nfet_01v8 w=20 l=0.5
Xtail tail nbias vss vss sky130_fd_pr__nfet_01v8 w=12 l=1.0
Rbias vdd_in nbias 60k
Xbias nbias nbias vss vss sky130_fd_pr__nfet_01v8 w=12 l=1.0

X3 n1 n1 vdd_in vdd_in sky130_fd_pr__pfet_01v8 w=30 l=1.0
X4 n2 n1 vdd_in vdd_in sky130_fd_pr__pfet_01v8 w=30 l=1.0
X5 vgate n2 vdd_in vdd_in sky130_fd_pr__pfet_01v8 w=40 l=0.5
X6 vgate nbias vss vss sky130_fd_pr__nfet_01v8 w=20 l=1.0
Rcomp vgate n_comp 3.6k
Ccomp n_comp n2 22.0p

* Pass transistor (W/L = 2000u / 0.15u, 200 fingers of 10u)
Xpass vdd_core vgate vdd_in vdd_in sky130_fd_pr__pfet_01v8 w=10 l=0.15 m=200

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

* Digital Control Code Word Signals (Sweeping across 100 us: Code 31 -> 18 -> 8 -> 31 -> 8)
Vd4 d4 0 PWL(0u 1  15u 1  30u 0  65u 0  72u 1  85u 0  100u 0)
Vd3 d3 0 PWL(0u 1  15u 0  30u 1  65u 1  72u 1  85u 1  100u 1)
Vd2 d2 0 PWL(0u 1  15u 0  30u 0  65u 0  72u 1  85u 0  100u 0)
Vd1 d1 0 PWL(0u 1  15u 1  30u 0  65u 0  72u 1  85u 0  100u 0)
Vd0 d0 0 PWL(0u 1  15u 0  30u 0  65u 0  72u 1  85u 0  100u 0)

* Dynamic Digital Load Current: 5mA idle with 38mA dynamic compute burst from 40us to 60us
I_digital_load vdd_core 0 PULSE(5m 38m 40u 20n 20n 20u 100u)

* -------------------------------------------------------------
* Simulation Controls
* -------------------------------------------------------------
.control
echo "=========================================================="
echo "Running BSIM4 Transistor-Level Mixed-Signal Co-Sim (100 us)"
echo "=========================================================="

tran 20n 100u
let i_supply = -vdd1v8#branch
let p_supply = 1.80 * i_supply
wrdata mixed_signal_top_transient.data v(vdd_core) v(vref_dac) v(vbgr) i_supply p_supply

echo "BGR Reference Voltage:"
print v(vbgr)[100]
echo "Core Voltage at Boot (Code 31):"
print v(vdd_core)[100]
echo "Core Voltage Scaled (Code 8):"
print v(vdd_core)[2500]

echo "Transistor-Level Mixed-Signal Simulation Completed Successfully."
.endc

.end
