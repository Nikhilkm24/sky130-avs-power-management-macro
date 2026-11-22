---
trigger: always_on
description: Mandatory engineering repository standards, anti-hype principles, and technical honesty rules for VLSI, semiconductor, and hardware projects.
---

# Engineering Standards & Repository Guidelines

1. **Anti-Hype Principle**:
   - Never use promotional, marketing, or interview-centric language.
   - Do not write phrases such as "revolutionary", "game-changing", "this showcases my skills", or "why this project beats X in interviews".
   - The repository must read like a mature engineering report written by an engineer sharing technical insights.

2. **Technical Honesty & Evidence**:
   - Every claim must be substantiated by actual files in the repository.
   - Clearly distinguish between:
     * RTL Simulation (Icarus / Verilator)
     * Transistor-Level SPICE Simulation (ngspice)
     * Behavioral / Discrete-Time Modeling (Python)
     * Gate-Level Synthesis (Yosys)
     * Static Timing Analysis (OpenSTA)
     * Physical Design Implementation & Extraction (Custom Python DEF/SPEF generators)
     * Physical Verification (Magic DRC / LVS)
     * Silicon Fabrication (NEVER claim without physical foundry evidence)
   - Never present modeled values as measured physical silicon data.
   - Never invent or fabricate simulation, DRC, LVS, or timing closure results.

3. **Engineering Depth**:
   - Connect circuit/architecture theory to real parameters ($W/L$, resistor values, FSM states).
   - Document genuine limitations, replica path tracking mismatches, and corner sensitivities.
   - Maintain strict consistency between documentation and RTL/SPICE signal names.
