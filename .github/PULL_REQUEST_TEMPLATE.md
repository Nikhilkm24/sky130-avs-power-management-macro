## Summary of Changes

A concise, high-level overview of what this pull request changes and why.

---

## Subsystem Impacted
- [ ] `rtl/` (Synthesizable RTL, CPM, FSM controller, MAC load, Level shifters)
- [ ] `sim/` (Testbenches, functional verification harnesses)
- [ ] `analog/` (Transistor schematics, BGR, DAC, LDO, layout generators)
- [ ] `sta/` (SDC constraints, OpenSTA scripts, corner analysis)
- [ ] `synth/` (Yosys synthesis, gate-level netlists)
- [ ] `pd/` (Physical design, floorplanning, placement, CTS, routing, SPEF)
- [ ] `models/` (Python closed-loop simulators, analytical energy models)
- [ ] `docs/` (Technical specifications, manuals, datasheets)
- [ ] `build/` (Makefile, CI workflows, tooling configuration)

---

## Motivation & Engineering Context

Explain the design reasoning, engineering problem, or architectural justification for this change. Reference any relevant Issue numbers if applicable.

---

## Technical Details

Highlight the key technical modifications:
- Architectural / schematic updates:
- Interface or register changes:
- Operating corner or constraint modifications:

---

## Verification & Test Evidence

List the verification commands executed and attach or summarize the results:

```bash
# Example verification runs
make sim
make analog
make sta
make validate
```

### Sign-off Results
- **RTL Functional Verification**: [Passed / Not Applicable]
- **Static Timing Analysis (Pre-route)**: [Slack TT: ____ ns | SS: ____ ns | FF: ____ ns]
- **Static Timing Analysis (Post-route)**: [Slack TT: ____ ns | SS: ____ ns | FF: ____ ns]
- **Physical Verification**: [DRC Violations: 0 | LVS Match: Clean / Not Applicable]
- **Transistor Simulation**: [LDO Phase Margin: ____ deg | BGR Tempco: ____ ppm/°C]

---

## Contributor Checklist

Before requesting review, ensure that:
- [ ] My code conforms to the project's formatting and styling guidelines (`.editorconfig`, PEP 8).
- [ ] Synthesizable RTL does not contain `#` simulation delays or unhandled latches.
- [ ] All relevant testbenches and simulations have been executed and passed.
- [ ] Timing sign-off passes across all target corners without setup or hold violations.
- [ ] Documentation has been updated to reflect any functional or architectural changes.
- [ ] No temporary files (`*.vcd`, `*.vvp`, `*.raw`, `*.log`, `*.data`, `.venv/`) or credentials are staged.
- [ ] Commit messages follow the Conventional Commits specification.
