# Contributing to Sky130 AVS Power Management Macro

Thank you for your interest in the **Sky130 Adaptive Voltage Scaling (AVS) Power Management Macro** project. This document outlines our development standards, engineering practices, branch workflows, and verification requirements to ensure high-quality, reproducible contributions.

---

## 1. Governance and Licensing Notice

> [!IMPORTANT]
> **Proprietary & Educational Use Notice**
> This repository is maintained for educational, academic research, and engineering portfolio reference purposes under the terms specified in [`LICENSE`](LICENSE).
> - All source code, schematics, netlists, and documentation are proprietary.
> - Unauthorized commercial use, redistribution, or deployment is prohibited.
> - Any contribution submitted to this repository constitutes agreement that the work will be governed under the project's existing license terms.

---

## 2. Before You Begin

Before opening a pull request or proposing major architectural modifications:

1. **Review the Architectural Specification**: Read [`README.md`](README.md), [`docs/SYSTEM_ARCHITECTURE.md`](docs/SYSTEM_ARCHITECTURE.md), and [`docs/SPECIFICATION.md`](docs/SPECIFICATION.md) to understand closed-loop control dynamics, analog operating limits, and timing constraints.
2. **Review the Verification Plan**: Inspect [`docs/verification_plan.md`](docs/verification_plan.md) to ensure your planned changes include adequate coverage.
3. **Check Build Requirements**: Consult [`BUILDING.md`](BUILDING.md) to verify your local toolchain matches the required open-source EDA versions (Icarus Verilog, Yosys, OpenSTA, Magic, Netgen, ngspice).
4. **Search Existing Issues and PRs**: Avoid duplicate efforts by verifying whether the bug or feature is already tracked.

---

## 3. Repository Organization & Subsystem Boundaries

To maintain clean separation of concerns, all files must be placed within their designated subsystems:

| Directory | Scope & Permitted Content | Strictly Prohibited Content |
|---|---|---|
| `rtl/` | Synthesizable Verilog-2001 / SystemVerilog RTL modules | Testbenches, delays (`#`), simulation-only constructs |
| `sim/` | Testbenches, verification harnesses, co-simulation scripts | Golden synthesizable RTL logic |
| `analog/` | SPICE netlists, models, and layout generators | Unparameterized netlists, proprietary foundry PDK dumps |
| `sta/` | SDC timing constraints, OpenSTA scripts, timing models | Ad-hoc delay assumptions, unverified clock specs |
| `synth/` | Yosys synthesis scripts, liberty mappings, gate netlists | Manual gate edits bypassing synthesis scripts |
| `pd/` | Floorplan, placement, CTS, routing, and SPEF scripts | Massive transient run logs, intermediate scratch files |
| `models/` | High-level Python behavioral and closed-loop simulators | Arbitrary unvalidated analytical curves |
| `reports/` | Curated, reproducible sign-off data, logs, and plots | Raw multi-gigabyte VCDs, transient dump files |
| `docs/` | Technical specifications, datasheets, architectural diagrams | Informal scratch notes or interview guides |

---

## 4. Development Workflow

We follow a disciplined branch-and-PR workflow inspired by Prometheus and Docker Compose.

### Step 1: Synchronize with Upstream Main
```bash
git checkout main
git pull origin main
```

### Step 2: Create a Focused Branch
Branch names must reflect the target subsystem and a concise description:
- `feature/<subsystem>-<description>` (e.g., `feature/cpm-dynamic-delay-line`)
- `bugfix/<subsystem>-<description>` (e.g., `bugfix/ldo-opamp-phase-margin`)
- `sta/<description>` (e.g., `sta/ss-corner-hold-timing`)
- `docs/<description>` (e.g., `docs/update-verification-plan`)
- `refactor/<subsystem>-<description>` (e.g., `refactor/fsm-state-encoding`)

```bash
git checkout -b feature/ldo-line-transient-fix
```

### Step 3: Implement and Validate Locally
Always run local validation before staging commits:
```bash
# Run RTL functional simulations
make sim

# Run transistor-level analog simulations
make analog

# Run multi-corner timing sign-off
make sta

# Run full Stage 1-5 validation
make validate
```

### Step 4: Commit with Conventional Commit Messages
Commits must be logical, focused, and follow the Conventional Commits specification:
- `feat(rtl): add programmable filter to CPM output`
- `fix(analog): adjust compensation capacitance for 75 deg PM at 0.9V`
- `docs(sta): document post-route SPEF back-annotation setup`
- `test(sim): add emergency droop recovery test case`
- `refactor(synth): parameterize Yosys synthesis script for cell count`

---

## 5. Engineering Standards & Quality Checklist

### RTL Design Guidelines
- Synthesizable subset only: No `#` delays in `rtl/`.
- Explicit resets: All sequential state elements must have clean, asynchronous or synchronous active-low resets.
- Non-blocking assignments (`<=`) for sequential blocks; blocking assignments (`=`) for purely combinational blocks.
- Zero latch inference: Ensure all `case` and `if-else` structures have complete default assignments.
- Clean lint: Must compile without warnings in Icarus Verilog (`iverilog -Wall`).

### Analog Design Guidelines
- Netlists in `analog/` must declare operating supply, ground, temperature, and corner conditions explicitly.
- Use `.measure` statements in SPICE netlists to extract critical performance metrics automatically.
- Do not commit proprietary PDK files or encrypted models. Reference standard SkyWater 130 open models.

### Static Timing Analysis Guidelines
- All timing paths must meet constraints across all sign-off corners:
  - **TT** (Typical): 1.20 V, 25 °C
  - **SS** (Slow): 0.90 V, 125 °C
  - **FF** (Fast): 1.50 V, -40 °C
- Pre-route and post-route timing analyses must both report **0 setup violations** and **0 hold violations**.

### Python & Scripting Guidelines
- Adhere to PEP 8 style conventions.
- Maintain pinned dependencies in `requirements.txt` / virtual environment.
- Use deterministic seeds when generating randomized test vectors.

---

## 6. Pull Request Submission Checklist

When opening a Pull Request using [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md), verify that:

- [ ] The PR addresses a single focused problem or architectural improvement.
- [ ] Code strictly complies with the repository's `.editorconfig` rules.
- [ ] Appropriate testbenches or simulation scripts have been executed and passed.
- [ ] Verification evidence (simulation logs, OpenSTA slack tables, or waveform plots) is provided in the PR description.
- [ ] Documentation has been updated to reflect any behavioral or interface changes.
- [ ] No temporary files (`*.vcd`, `*.vvp`, `*.raw`, `*.log`, `*.data`) or credentials are staged.
- [ ] All automated GitHub Actions CI checks pass green.

---

## 7. Review and Merging Process

1. Every pull request undergoes automated continuous integration (`.github/workflows/ci.yml`).
2. The project maintainer reviews the technical implementation for architectural alignment, timing margins, and documentation clarity.
3. Upon approval and green CI status, the PR is squash-merged or rebase-merged into `main` to maintain a clean linear Git history.
