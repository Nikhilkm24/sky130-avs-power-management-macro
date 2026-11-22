# Sky130 AVS Power Management Macro — Technical Documentation

Welcome to the comprehensive technical documentation for the **Closed-Loop Adaptive Voltage Scaling (AVS) Power Management Macro** designed for the **SkyWater 130nm (sky130_fd_sc_hd)** CMOS process.

This documentation suite provides complete architectural descriptions, electrical specifications, verification plans, layout methodologies, and sign-off reports.

---

## Documentation Navigation Matrix

| Document | Primary Audience | Scope & Key Contents |
|---|---|---|
| [**System Architecture**](SYSTEM_ARCHITECTURE.md) | Mixed-Signal & Systems Engineers | Detailed architectural breakdown of the 6 core subsystems: BGR, 5-bit R-string DAC, Folded-Cascode LDO, Critical Path Monitor (CPM), AVS Controller FSM, and Dual-Rail Level Shifters. Includes block diagrams, interface protocols, and closed-loop feedback theory. |
| [**Electrical Specification**](SPECIFICATION.md) | Analog & Power Designers | Target operating parameters, power supply ranges ($V_{DD} = 1.80\text{ V}$, $V_{CORE} = 0.90\text{--}1.50\text{ V}$), regulation tolerances, step resolution ($19.35\text{ mV}$), transient recovery targets, and silicon area budgets. |
| [**Hardware Verification Plan**](verification_plan.md) | Verification & Quality Engineers | Comprehensive coverage matrix across RTL functional verification, transistor-level SPICE simulations, multi-corner Static Timing Analysis (pre- and post-route), physical verification (DRC/LVS), and closed-loop co-sim. |
| [**LDO Datasheet Summary**](LDO_DATASHEET_SUMMARY.md) | Analog Designers & Integrators | Electrical parameters of the integrated LDO regulator: loop gain ($68.4\text{ dB}$), phase margin ($74.9^\circ$), unity-gain bandwidth ($11.62\text{ MHz}$), load transient droop ($42\text{ mV}$), line regulation, and thermal characteristics. |
| [**Future Development Roadmap**](ROADMAP.md) | Contributors & Maintainers | Phased development milestones (Milestones 1 through 6): mixed-signal transistor co-sim, dynamic clock frequency scaling, on-chip thermal throttling, multi-corner Monte Carlo mismatch analysis, and tapeout readiness. |
| [**Complete Engineering Manual**](COMPLETE_PROJECT_DOCUMENTATION.md) | Comprehensive Reference | Consolidated technical manual containing end-to-end design rationale, mathematical formulations, SPICE netlist documentation, synthesis constraints, and physical design methodology. |
| [**Building & Toolchain Guide**](../BUILDING.md) | All Engineers / New Setups | Complete instructions for installing and configuring open-source EDA tools (Icarus Verilog, Yosys, OpenSTA, Magic, Netgen, ngspice) on Linux and WSL2. |
| [**Contribution Guidelines**](../CONTRIBUTING.md) | Contributors & Reviewers | Branch workflows, coding and design standards, sign-off checklists, and commit standards. |

---

## System Subsystem Overview

```
                      +---------------------------------------------------------+
                      |                 UNREGULATED SUPPLY (VDD = 1.80V)        |
                      +-------------------+-----------------+-------------------+
                                          |                 |
                                          v                 v
                                  +---------------+   +-----------+
                                  | Bandgap (BGR) |   | 5-bit DAC |
                                  |  VREF = 1.20V |-->|  R-String |
                                  +---------------+   +-----+-----+
                                                            | VDAC_REF (0.90V - 1.50V)
                                                            v
+-----------------------+     VDD_REG       +-----------------------------------+
|  REGULATED CORE LOAD  |<------------------|  Folded-Cascode LDO Regulator     |
|  - 16-bit MAC Load    |   (0.90V - 1.50V) |  (PMOS Pass Device, Ccomp, Rcomp)  |
|  - Critical Path Mon  |                   +-----------------+-----------------+
+-----------+-----------+                                     ^
            |                                                 |
       CPM Output                                             | 5-bit Voltage Code
       (Early/Late)                                           | [4:0]
            v                                                 |
+-----------------------+                            +--------+---------+
|  AVS Controller FSM   |----------------------------| Level Shifter    |
|  (Hysteresis & Rate)  |   5-bit Target Code (VCORE)| (Dual-Rail Safe) |
+-----------------------+                            +------------------+
```

---

## Verifying Results

All claims and metrics in this documentation suite can be independently reproduced using the repository build system:

```bash
# 1. Functional simulation
make sim

# 2. Analog transistor characterization
make analog

# 3. Static timing analysis across corners
make sta

# 4. Physical design and post-route sign-off
make pd
make post_route_sta

# 5. Closed-loop dynamic verification
make model
make pvt_matrix
```
