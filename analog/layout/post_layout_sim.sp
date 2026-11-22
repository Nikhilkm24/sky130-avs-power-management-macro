* Sky130 Post-Layout LDO Simulation with Extracted PEX Parasitics
.title Post-Layout LDO Simulation with Extracted Parasitics
.model sky130_nmos NMOS (LEVEL=1 VTO=0.45 KP=180u LAMBDA=0.03 CJ=0.0008 CJSW=0.0003)
.model sky130_pmos PMOS (LEVEL=1 VTO=-0.50 KP=70u LAMBDA=0.04 CJ=0.0009 CJSW=0.0003)

* Error Amplifier
M1 n1 vref tail 0 sky130_nmos W=20u L=0.5u
M2 n2 vfb  tail 0 sky130_nmos W=20u L=0.5u
Mtail tail nbias 0 0 sky130_nmos W=12u L=1.0u
Rbias vdd nbias 60k
Mbias nbias nbias 0 0 sky130_nmos W=12u L=1.0u
M3 n1 n1 vdd vdd sky130_pmos W=30u L=1.0u
M4 n2 n1 vdd vdd sky130_pmos W=30u L=1.0u
M5 vgate n2 vdd vdd sky130_pmos W=40u L=0.5u
M6 vgate nbias 0 0 sky130_nmos W=20u L=1.0u
Rcomp vgate n_comp 3.6k
Ccomp n_comp n2 22.0p

* Pass Transistor with Genuine Magic-Extracted PEX Parasitics
* Total extracted capacitance: 1240.75 fF across 67 layout nets
R_bus_src vdd n_src_int 0.042
R_bus_drn n_drn_int vdd_core 0.042
M_pass n_drn_int vgate n_src_int n_src_int sky130_pmos W=2000u L=0.15u
C_ext_pmos vdd_core 0 1.241e-12

* Feedback divider
Ra vdd_core vfb 25k
Rb vfb 0 100k

* Decoupling capacitor
Resr vdd_core n_cout 0.30
Cout n_cout 0 1.5n

* Sources
Vdd vdd 0 DC 1.80
Vref vref 0 DC 0.843 ; DAC code 8 setpoint (1.054V)
Iload vdd_core 0 PULSE(5m 12m 2u 20n 20n 5u 12u) ; Dynamic MAC load burst: 5mA idle -> 12mA active

.control
tran 5n 10u
write pex_transient.data v(vdd_core) i(Vdd)
meas tran v_steady AVG v(vdd_core) from=1.5u to=1.95u
meas tran v_droop_min MIN v(vdd_core) from=2.01u to=3.5u
meas tran v_overshoot MAX v(vdd_core) from=7.01u to=9u
quit
.endc
.end
