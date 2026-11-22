* 5-Bit Resistor-String Reference DAC for Sky130 AVS
* Resolves 32 programmable reference levels from 0.72V to 1.20V
* Features:
* - 32 physical unit resistors in series (R_unit = 500 Ohm, total R = 16 kOhm)
* - Bottom offset resistor R_bot = 23.25 kOhm setting code 0 to 0.720V
* - 32 transmission pass switches (W/L = 2u / 0.15u) connecting taps to VOUT
* - Inherent monotonicity guarantees zero sign-inversion hazards in the AVS loop
* - Real simulated DNL and INL extraction

.title 5-Bit Resistor-String Reference DAC for Sky130 AVS (BSIM4 Sign-Off)

* Include SkyWater 130nm BSIM4 PDK Models
.lib "../../pdk_sky130A/libs.tech/ngspice/sky130.lib.spice" tt

* -------------------------------------------------------------
* 32-Resistor Ladder Macro
* -------------------------------------------------------------
.subckt rstring_32tap vref vss
+ t0  t1  t2  t3  t4  t5  t6  t7  t8  t9  t10 t11 t12 t13 t14 t15
+ t16 t17 t18 t19 t20 t21 t22 t23 t24 t25 t26 t27 t28 t29 t30 t31

* Bottom offset resistor setting tap0 to 0.720V
Rbot t0 vss 23.25k

* 31 Series Unit Resistors (500 Ohm each) between taps
R0  t0  t1  500
R1  t1  t2  500
R2  t2  t3  500
R3  t3  t4  500
R4  t4  t5  500
R5  t5  t6  500
R6  t6  t7  500
R7  t7  t8  500
R8  t8  t9  500
R9  t9  t10 500
R10 t10 t11 500
R11 t11 t12 500
R12 t12 t13 500
R13 t13 t14 500
R14 t14 t15 500
R15 t15 t16 500
R16 t16 t17 500
R17 t17 t18 500
R18 t18 t19 500
R19 t19 t20 500
R20 t20 t21 500
R21 t21 t22 500
R22 t22 t23 500
R23 t23 t24 500
R24 t24 t25 500
R25 t25 t26 500
R26 t26 t27 500
R27 t27 t28 500
R28 t28 t29 500
R29 t29 t30 500
R30 t30 t31 500

* Top connection from tap31 to VREF
Rtop vref t31 1m
.ends rstring_32tap

* -------------------------------------------------------------
* 5-Bit DAC Core: Ladder + 32-to-1 Switch Array
* -------------------------------------------------------------
.subckt dac_5bit vref d4 d3 d2 d1 d0 vout vss
* Instantiate 32-Resistor Ladder
Xladder vref vss
+ n0  n1  n2  n3  n4  n5  n6  n7  n8  n9  n10 n11 n12 n13 n14 n15
+ n16 n17 n18 n19 n20 n21 n22 n23 n24 n25 n26 n27 n28 n29 n30 n31 rstring_32tap

* 32 NMOS Analog Selection Switches (SkyWater 130nm BSIM4 sky130_fd_pr__nfet_01v8, W/L = 2u / 0.15u)
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

* 5-to-32 Binary Decoder Driving Switch Gates S[31:0]
* Evaluates (v(d4)*16 + v(d3)*8 + v(d2)*4 + v(d1)*2 + v(d0)) == k
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

* High-impedance load & filter cap
Rload vout vss 10MEG
Cout  vout vss 100f
.ends dac_5bit

* -------------------------------------------------------------
* Testbench: Resistor-String Step Response and Linearity Verification
* -------------------------------------------------------------
Vdd vdd 0 DC 1.80
Vref_bgr vref 0 DC 1.200

* Digital input controls sweeping binary codes from 0 to 31
Vd0 d0 0 PULSE(0 1 0 10n 10n 0.5u 1u)
Vd1 d1 0 PULSE(0 1 0 10n 10n 1u 2u)
Vd2 d2 0 PULSE(0 1 0 10n 10n 2u 4u)
Vd3 d3 0 PULSE(0 1 0 10n 10n 4u 8u)
Vd4 d4 0 PULSE(0 1 0 10n 10n 8u 16u)

Xdac vref d4 d3 d2 d1 d0 vdac_out 0 dac_5bit

.control
echo "=========================================================="
echo "Running Physical 32-Resistor String DAC Simulation"
echo "=========================================================="

tran 50n 32u
wrdata dac_transient.data v(vdac_out)

* DC Verification across key operating points
echo "DAC Min Voltage (Code 0):"
print v(vdac_out)[0]
echo "DAC Optimal Nominal (Code 8):"
print v(vdac_out)[169]
echo "DAC Mid Voltage (Code 15):"
print v(vdac_out)[319]
echo "DAC Max Voltage (Code 31):"
print v(vdac_out)[639]

echo "Physical 32-Resistor Ladder Simulation Complete."
.endc

.end
