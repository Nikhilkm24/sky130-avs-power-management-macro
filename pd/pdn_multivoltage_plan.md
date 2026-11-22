# Multi-Voltage Physical Design & Power Distribution Network (PDN) Plan

## 1. Physical Architecture & Macro Partitioning
To overcome open-source EDA single-rail limitations, the AVS macro utilizes a **hierarchical dual-domain physical partitioning**:

```
+---------------------------------------------------------------------------------------------------+
|  AVS Top-Level Macro Floorplan (Die Area: 450 um x 320 um)                                       |
|                                                                                                   |
|  +-------------------------------------+   +---------------------------------------------------+  |
|  | Analog Subsystem (VDD_1V8 = 1.8V)   |   | Core Digital Domain (VDD_CORE = 0.90V - 1.50V)    |  |
|  |                                     |   |                                                   |  |
|  |  +-------------------------------+  |   |  +---------------------------------------------+  |  |
|  |  | 1.20V Bandgap Reference       |  |   |  | Pipelined MAC 16-Bit Compute Engine         |  |  |
|  |  | (Brokaw BJT array + Guard ring|  |   |  | (High-density standard cell rows, 65% util) |  |  |
|  |  +-------------------------------+  |   |  +---------------------------------------------+  |  |
|  |                                     |   |                                                   |  |
|  |  +-------------------------------+  |   |  +---------------------------------------------+  |  |
|  |  | 5-Bit Resistor-String DAC     |  |   |  | Replica Critical Path Monitor (CPM)         |  |  |
|  |  | (Common-centroid matrix)      |  |   |  | (Direct silicon tracking near MAC center)   |  |  |
|  |  +-------------------------------+  |   |  +---------------------------------------------+  |  |
|  |                                     |   |                                                   |  |
|  |  +-------------------------------+  |   +---------------------------------------------------+  |
|  |  | Programmable LDO Regulator    |  |     ||  Low-to-High Level Shifter Isolation Boundary     |
|  |  | (PMOS Pass + Miller OTA)      |==+====>||  (sky130_fd_sc_hd__lpflow_lsbuf_lh_1 array)      |
|  |  +-------------------------------+  |  VDD_CORE                                                |
|  +-------------------------------------+   +---------------------------------------------------+  |
|                                            | AVS Controller FSM (VDD_1V8 Domain)               |  |
|                                            | (Hysteresis, Settle Counter, Emergency Alarm)     |  |
|                                            +---------------------------------------------------+  |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Power Distribution Network (PDN) Specifications

| Rail Name | Target Voltage | Routing Layers | Min Width ($\mu\text{m}$) | Pitch ($\mu\text{m}$) | IR Drop Limit | Current Rating |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `VDD_1V8` | $1.80\text{ V} \pm 10\%$ | met4 (V), met5 (H) | 2.4 | 20.0 | $< 15\text{ mV}$ ($< 0.8\%$) | $15\text{ mA}$ |
| `VDD_CORE`| $0.90\text{ V} - 1.50\text{ V}$ | met4 (V), met5 (H) | 4.8 | 15.0 | $< 20\text{ mV}$ ($< 1.8\%$) | $50\text{ mA}$ |
| `VSS` | $0.0\text{ V}$ (Ground) | met4 (V), met5 (H) | 4.8 | 15.0 | $< 10\text{ mV}$ | $65\text{ mA}$ return |

### 2.1 Electromigration (EM) Sizing
Based on the Sky130 Process Design Kit EM limits ($J_{MAX} \approx 1.0\text{ mA}/\mu\text{m}$ at $105^\circ\text{C}$):
- Maximum total core current $I_{PEAK} = 50\text{ mA}$.
- Minimum required top metal aggregate width: $W_{min} = 50\text{ mA} / (1.0\text{ mA}/\mu\text{m}) = 50\,\mu\text{m}$.
- Implemented as $12 \times 4.8\,\mu\text{m}$ straps across the macro core grid $\rightarrow$ **Safety margin $> 15\%$ over worst-case EM limit**.

---

## 3. Level-Shifter Placement & Isolation Halo
1. A physical isolation halo of $5\,\mu\text{m}$ is enforced between the $V_{DD,1V8}$ controller domain and the $V_{DD,CORE}$ datapath domain.
2. Level shifters (`sky130_fd_sc_hd__lpflow_lsbuf_*`) are placed in dedicated boundary rows with tap cells providing clean body bias (`VPB` connected to highest potential $1.8\text{ V}$, `VNB` connected to `VSS`).
3. Antenna diode insertion (`sky130_fd_sc_hd__diode_2`) is enforced on all long interconnect routes exceeding $150\,\mu\text{m}$ metal gate ratio.
