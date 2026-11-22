---
name: Bug Report
about: Report an unexpected simulation failure, timing violation, DRC/LVS error, or build issue.
title: "[BUG] <concise description of the failure>"
labels: bug
assignees: ''
---

## 1. Subsystem Affected
- [ ] RTL (`rtl/`)
- [ ] Analog / Mixed-Signal (`analog/`)
- [ ] Static Timing Analysis (`sta/`)
- [ ] Synthesis (`synth/`)
- [ ] Physical Design & Layout (`pd/`, `analog/layout/`)
- [ ] Modeling & Python (`models/`)
- [ ] Build System & Scripts (`Makefile`, `.github/`)
- [ ] Documentation (`docs/`, `README.md`)

## 2. Bug Summary
A clear and concise description of what the unexpected behavior or failure is.

## 3. Expected Behavior
A concise description of what you expected to happen according to the design specification.

## 4. Actual Behavior
What actually occurred (include exact error code, unexpected waveform, negative slack, etc.).

## 5. Steps to Reproduce
1. Clone the repository and activate environment:
   ```bash
   git checkout <branch>
   source .venv/bin/activate
   ```
2. Run the command:
   ```bash
   make <target> # or exact script invocation
   ```
3. Observe failure at:
   ```
   ...
   ```

## 6. Environment & Toolchain Details
- **OS**: [e.g. Ubuntu 24.04 on WSL2, Ubuntu 22.04 native]
- **Icarus Verilog (`iverilog -v`)**:
- **ngspice (`ngspice -v`)**:
- **OpenSTA (`sta -version`)**:
- **Yosys (`yosys -V`)**:
- **Magic VLSI (`magic --version`)**:
- **Python version (`python3 --version`)**:

## 7. Relevant Logs & Output
<details>
<summary>Console / Simulator Output</summary>

```text
PASTE LOG HERE
```
</details>

## 8. Additional Context / Possible Root Cause
Add any other context about the problem here, such as relevant timing paths, corner conditions (TT, SS, FF), or schematic operating points.
