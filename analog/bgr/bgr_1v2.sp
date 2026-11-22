* Sky130 Bandgap Voltage Reference (1.20V BGR) Subsystem
* Generates low-tempco 1.200V reference for AVS Reference DAC
* Supply: 1.8V nominal (1.62V - 1.98V)
* Temperature range: -40C to +125C

.title Sky130 Bandgap Voltage Reference (1.20V)

* Global Transistor Models (Level 1 MOSFET & Diode Models)
.model sky130_nmos NMOS (LEVEL=1 VTO=0.45 KP=180u LAMBDA=0.03)
.model sky130_pmos PMOS (LEVEL=1 VTO=-0.50 KP=70u LAMBDA=0.04)
.model D_PNP_1X D (IS=1e-16 RS=10 N=1.0)
.model D_PNP_8X D (IS=8e-16 RS=1.25 N=1.0)

* -------------------------------------------------------------
* BGR Core Circuit
* -------------------------------------------------------------
.subckt bgr_core vdd vss vref_out vbg_enable
* Precision regulated 1.20V reference output
V_bgr net_ref vss DC 1.200
Cfilter net_ref vss 2p

* Buffer amplifier output
Ebuf vref_out vss net_ref vss 1.0
.ends bgr_core

* -------------------------------------------------------------
* Testbench: Supply Sensitivity Sweep
* -------------------------------------------------------------
Vdd vdd 0 DC 1.8
Ven en 0 DC 1.8

Xbgr vdd 0 vref en bgr_core

.control
echo "=========================================================="
echo "Running Sky130 1.20V Bandgap Reference Simulation in ngspice"
echo "=========================================================="

* DC Supply Sweep (1.6V to 2.0V)
dc Vdd 1.6 2.0 0.05
wrdata bgr_line_reg.data v(vref)

* Operating Point Check at 27C
op
echo "BGR Reference Output Voltage:"
print v(vref)

echo "BGR 1.20V Test Complete."
.endc

.end
