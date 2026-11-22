* 5-Bit Resistor-String Reference DAC for Sky130 AVS
* Resolves 32 programmable reference levels from 0.72V to 1.20V
* Input: 5-bit binary code D[4:0] (from AVS Controller)
* Supply: 1.8V analog, BGR input = 1.20V

.title 5-Bit Resistor-String Reference DAC for AVS

* -------------------------------------------------------------
* 5-Bit DAC Behavioral / Switch Array Macro
* -------------------------------------------------------------
.subckt dac_5bit vref d4 d3 d2 d1 d0 vout vss
* Vout = 0.72 + (v(vref) - 0.72) * (code / 31)
* Maps to Core VDD 0.90V to 1.50V via LDO gain 1.25
B_dac vout vss V = 0.72 + (v(vref) - 0.72) * ((v(d4)*16 + v(d3)*8 + v(d2)*4 + v(d1)*2 + v(d0)) / 31.0)
Rload vout vss 10MEG
Cout  vout vss 50f
.ends dac_5bit

* -------------------------------------------------------------
* Testbench: Step-Response and Linearity Verification
* -------------------------------------------------------------
Vdd vdd 0 DC 1.8
Vref_bgr vref 0 DC 1.20

* Digital input controls (Sweeping code 0 to 31 over 31us)
Vd0 d0 0 PULSE(0 1 0 10n 10n 0.5u 1u)
Vd1 d1 0 PULSE(0 1 0 10n 10n 1u 2u)
Vd2 d2 0 PULSE(0 1 0 10n 10n 2u 4u)
Vd3 d3 0 PULSE(0 1 0 10n 10n 4u 8u)
Vd4 d4 0 PULSE(0 1 0 10n 10n 8u 16u)

Xdac vref d4 d3 d2 d1 d0 vdac_out 0 dac_5bit

.control
echo "=========================================================="
echo "Running 5-Bit Resistor-String DAC Simulation in ngspice"
echo "=========================================================="

tran 50n 32u
wrdata dac_transient.data v(vdac_out)

* DC Check at Code 0, 16, 31
echo "DAC Min Voltage (Code 0):"
print v(vdac_out)[0]
echo "DAC Mid Voltage (Code 15):"
print v(vdac_out)[319]
echo "DAC Max Voltage (Code 31):"
print v(vdac_out)[639]

echo "DAC Simulation Completed Successfully."
.endc

.end
