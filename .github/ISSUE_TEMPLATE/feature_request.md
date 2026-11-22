---
name: Feature Request
about: Propose an architectural enhancement, new analog cell, timing optimization, or tooling improvement.
title: "[FEAT] <concise description of proposed enhancement>"
labels: enhancement
assignees: ''
---

## 1. Subsystem
- [ ] RTL Architecture (`rtl/`)
- [ ] Analog / Power Management (`analog/`)
- [ ] Timing Sign-off / Constraints (`sta/`)
- [ ] Synthesis & Optimization (`synth/`)
- [ ] Physical Design / Layout (`pd/`, `analog/layout/`)
- [ ] Closed-Loop Modeling & Analytics (`models/`)
- [ ] Tooling / CI Automation (`Makefile`, `.github/`)
- [ ] Documentation (`docs/`)

## 2. Problem Statement / Motivation
Is your feature request related to a specific hardware limitation, performance bottleneck, or verification gap? Please describe the motivation clearly.

## 3. Proposed Solution / Architectural Concept
Describe the proposed technical approach, block-level modifications, or new modules:
- What signals or interfaces are added/modified?
- What are the control dynamics or timing implications?
- How does it interface with existing AVS blocks (LDO, DAC, BGR, CPM, Controller)?

## 4. Hardware Trade-offs
Evaluate the architectural trade-offs:
- **Power**: Expected impact on static/dynamic power.
- **Performance**: Impact on maximum operating frequency or transient response time.
- **Area**: Expected gate count or silicon area increase.
- **Design Complexity**: Impact on routing congestion, timing closure, or DRC/LVS rules.

## 5. Alternatives Considered
Describe any alternative implementations or techniques you considered and why you chose this approach.

## 6. Verification and Acceptance Criteria
What specific testbenches, simulation runs, or sign-off criteria must pass for this feature to be considered complete?
- [ ] RTL simulation testbench passed
- [ ] Timing closure across TT, SS, FF corners with >= 0.00 ns slack
- [ ] DRC/LVS verified clean
- [ ] Closed-loop transient stability verified
- [ ] Technical documentation updated
