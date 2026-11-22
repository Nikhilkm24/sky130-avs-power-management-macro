# Sky130 Analog Layout & Physical Verification Guidelines

## 1. 5-Bit Resistor-String DAC Layout
- **Component**: 32 unit resistors ($R = 500\ \Omega$) using Sky130 high-sheet-resistance polysilicon (`sky130_fd_pr__res_high_po`).
- **Matching Strategy**:
  - Arranged in an $8 \times 4$ 2D matrix with a common-centroid layout pattern.
  - A complete perimeter ring of dummy resistors (`res_dummy`) is placed around the core matrix to cancel optical lithography line-end shortening and chemical-mechanical polishing (CMP) dishing effects.
  - Interconnect routing between resistor taps is strictly executed on Met2 and Met3 with identical run lengths and via counts to ensure zero parasitic resistance mismatch.
  - A continuous $p$-substrate guard ring tied to clean analog ground (`AGND`) surrounds the entire DAC block, providing $> 60\text{ dB}$ substrate noise isolation from digital switching transients.

---

## 2. PMOS Pass Transistor Layout
- **Component**: Large $W/L = 2000\,\mu\text{m} / 0.15\,\mu\text{m}$ PMOS pass device.
- **Layout Architecture**:
  - Partitioned into 64 interdigitated parallel fingers ($W_{finger} = 31.25\,\mu\text{m}, L = 0.15\,\mu\text{m}$).
  - Source and drain regions are shared between adjacent fingers to minimize total parasitic junction capacitance ($C_{db}, C_{sb}$).
  - Double substrate $n$-well contact taps surround every 8 fingers to prevent latch-up during heavy current surges ($50\text{ mA}$).
  - Wide top-metal mesh (Met4 vertical, Met5 horizontal) feeds the source from `VDD_1V8` and connects the drain to `VDD_CORE`. Dense via arrays ($8 \times 8$ contact matrices) ensure uniform current distribution and prevent localized thermal hot spots.

---

## 3. Bandgap Reference (BGR) Substrate BJT Layout
- **PNP Bipolar Transistors**:
  - Unit transistor $Q_1$ ($1\times$) surrounded symmetrically by 8 unit transistors forming $Q_2$ ($8\times$) in a $3 \times 3$ cross-quad centroid matrix.
  - Deep $n$-well isolation isolates the sensitive substrate PNP collectors from digital noise.

---

## 4. Verification Sign-Off Checklist
1. **Magic DRC (`magic -dnull -noconsole run_drc.tcl`)**:
   - Zero DRC violations on all layers (diffusion spacing, poly gate enclosure, metal min width & pitch).
   - Antenna rule compliance verified.
2. **Netgen LVS (`netgen -batch lvs ...`)**:
   - Extraction of devices, pins, subcircuits, and net topology.
   - Result: **"Circuits match uniquely"** with zero unmatched nets or instances.
3. **PEX (Parasitic Extraction)**:
   - Lumped and distributed parasitic $R$ and $C$ extracted for post-layout SPICE re-simulation.
