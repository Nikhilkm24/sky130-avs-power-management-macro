# Engineering Repository Standards and Documentation Rules

This document defines the persistent engineering standards and documentation philosophy for this repository and all future hardware, semiconductor, VLSI, analog, digital, machine-learning, and software projects developed in this environment.

---

## 1. General Repository Philosophy

1. **Knowledge Over Marketing**: Repositories must communicate genuine engineering work, design trade-offs, circuit theory, and empirical experimentation. Documentation exists to share technical understanding with other engineers, not to impress interviewers or recruiters.
2. **Strict Technical Honesty**: Every technical statement must be backed by verifiable code, netlists, simulation logs, or synthesis outputs. Never make speculative or unverified claims.
3. **Evidence-Based Categorization**: Every subsystem, metric, and feature must be clearly classified into one of:
   - *Implemented and Verified* (empirically confirmed by tools).
   - *Implemented but Not Independently Verified* (source exists, verification pending).
   - *Simulated or Modeled* (behavioral or numerical approximation).
   - *Partially Implemented* (active work in progress).
   - *Planned / Documented Only* (design intent documented, no code yet).
4. **Zero Fabrication**: Never fabricate simulation runs, timing closure reports, DRC/LVS logs, or power figures. Never present behavioral/modeled results as physical silicon measurements. Never claim tape-out, chip fabrication, or post-silicon validation without physical foundry and lab test evidence.
5. **No AI Clichés or Promotional Fluff**: Avoid generic AI-generated hyperbole (e.g., "revolutionary", "game-changing", "masterpiece", "unprecedented", "industry-leading"). Avoid interview-centric framing (e.g., "Why this beats X in interviews", "Talking points for recruiters").

---

## 2. Documentation Standards

1. **Connect Theory to Implementation**: Explain why a topology was chosen over alternatives (e.g., resistor-string DAC for strict monotonicity vs. R-2R ladder), state the mathematical governing equations, and link them to transistor parameters ($W/L$), passive values, or RTL architectures.
2. **Concrete Numerical Values & Units**: Use precise numbers extracted from genuine tools. Always include appropriate physical units ($\text{mV}$, $\mu\text{m}$, $\text{pJ/op}$, $\text{dB}$, $\text{MHz}$).
3. **Consistent Signal & Port Naming**: Terminology in Markdown documentation must match HDL port names, SPICE net names, and timing constraint labels exactly.
4. **Meaningful Diagrams**: Architectural diagrams must reflect real signal routing, clock domains, and power rail partitions rather than abstract conceptual blocks.
5. **Document Limitations Transparently**: Highlight genuine design challenges, corner cases, simulation caveats, and unverified edge cases (e.g., replica path mismatch, finite LDO PSRR at high frequencies, clock-domain crossing latency).
6. **Maintain Functional Relative Links**: Verify all file paths, relative markdown links, and embedded images. Never reference non-existent files.

---

## 3. Repository Organization Standards

1. **Functional Directory Partitioning**:
   - `rtl/`: Synthesizable Verilog / SystemVerilog source modules.
   - `analog/`: Transistor-level SPICE netlists, layout cells, and characterization scripts.
   - `sim/`: Testbenches, co-simulation harnesses, and stimulus files.
   - `sta/`: Timing constraints (`.sdc`), corner analysis scripts, and delay models.
   - `synth/`: Synthesis scripts, gate-level netlists, and mapping logs.
   - `pd/`: Physical design scripts, DEF floorplans, and extracted SPEF interconnects.
   - `models/`: High-level Python behavioral and mathematical simulation scripts.
   - `reports/`: Raw tool-generated execution logs, sign-off reports, and data plots.
   - `docs/`: In-depth architecture specifications, datasheets, and theory manuals.
2. **Clean Version Control Discipline**:
   - Maintain a comprehensive `.gitignore` excluding simulation waveform dumps (`*.vcd`, `*.raw`, `*.fst`), heavy PDK libraries (`*.lib` > 25MB), temporary EDA locks, and OS metadata.
   - Review every git diff prior to staging. Commit messages must follow conventional commit standards (`feat:`, `fix:`, `docs:`, `ci:`, `chore:`).
   - Keep generated artifacts and run logs clearly distinct from human-written source files.
