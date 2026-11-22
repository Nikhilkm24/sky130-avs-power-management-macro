# Research Portal: Closed-Loop Adaptive Voltage Scaling (AVS) Macro on Sky130

Welcome to the **Research & Novelty Development Portal** for the SkyWater 130nm Adaptive Voltage Scaling (AVS) Power Management Macro.

This directory contains the academic research roadmap, literature review, verification forensic audit, candidate architectures, publication-quality experimental proofs, and the phase-by-phase implementation guide to transition this project from an engineering prototype (`v1.4.1`) to an experimentally validated, peer-reviewed silicon macro (`v2.0.0`).

---

## 1. Primary Documents & Downloads

- 📄 **[Download Complete Research Implementation Guide (PDF)](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/Sky130_AVS_Research_Implementation_Guide.pdf)**  
  *A 7-page, high-density, publication-grade research monograph formatted with ReportLab containing the complete forensic audit, 30-paper literature matrix, mathematical models, 14 embedded high-resolution figures, and Phase A–K execution roadmap.*
- 📝 **[Comprehensive Research Implementation Guide (Markdown)](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/RESEARCH_IMPLEMENTATION_GUIDE.md)**  
  *The full unabridged reference document containing all 10 Deliverables, detailed mathematical derivations, 30 full literature extractions, and the complete experimental matrix.*

---

## 2. Publication-Quality Figures (`research/figures/`)

All figures are generated directly from verifiable OpenSTA timing logs, Magic PEX extracted parasitics, ngspice transient runs, and closed-loop co-simulations at 300 DPI:

| Figure | Filename | Description |
|---|---|---|
| **Fig 1** | [`fig1_voltage_vs_delay.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig1_voltage_vs_delay.png) | 16-bit MAC critical path vs 16-stage CPM replica delay across 0.85V–1.95V. |
| **Fig 2** | [`fig2_voltage_vs_margin.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig2_voltage_vs_margin.png) | Physical setup slack and quantized CPM margin code showing target deadband [2, 3]. |
| **Fig 3** | [`fig3_cpm_vs_sta_slack.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig3_cpm_vs_sta_slack.png) | In-situ CPM estimated margin vs actual OpenSTA timing slack ($R^2 = 0.6056$). |
| **Fig 4** | [`fig4_cpm_error_residuals.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig4_cpm_error_residuals.png) | Residual error distribution proving worst-case optimistic error is strictly $0.0\text{ ps}$. |
| **Fig 5** | [`fig5_cpm_uncertainty_pvt.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig5_cpm_uncertainty_pvt.png) | In-situ timing uncertainty decomposition ($T_{setup}$, $T_{jitter}$, quantization, mismatch). |
| **Fig 6** | [`fig6_workload_path_activation.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig6_workload_path_activation.png) | Dynamic switching current across 5 compute workloads (Idle to Peak burst). |
| **Fig 7** | [`fig7_load_current_vs_vcore.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig7_load_current_vs_vcore.png) | Post-layout LDO static load regulation ($0.1\text{ mA} \rightarrow 50\text{ mA}$). |
| **Fig 8** | [`fig8_regulator_transient_droop.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig8_regulator_transient_droop.png) | Post-PEX LDO transient load response ($72.9\text{ mV}$ droop, $26.6\text{ ns}$ settling). |
| **Fig 9** | [`fig9_avs_closed_loop_adaptation.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig9_avs_closed_loop_adaptation.png) | Closed-loop AVS transient trajectory and emergency fault recovery over $60\,\mu\text{s}$. |
| **Fig 10** | [`fig10_energy_per_op_vs_voltage.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig10_energy_per_op_vs_voltage.png) | Digital core energy per operation vs voltage ($50.61\%$ reduction at $1.054\text{ V}$). |
| **Fig 11** | [`fig11_total_system_energy_breakdown.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig11_total_system_energy_breakdown.png) | System energy accounting breakdown reconciling core dynamic vs net system savings ($37.12\%$). |
| **Fig 12** | [`fig12_controller_overhead_tradeoff.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig12_controller_overhead_tradeoff.png) | Controller clock frequency ($12.5\text{ MHz}$) vs convergence time and power overhead. |
| **Fig 13** | [`fig13_timing_safety_tradeoff.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig13_timing_safety_tradeoff.png) | Guard-band trade-off: Timing hazard probability vs energy efficiency. |
| **Fig 14** | [`fig14_ablation_comparison.png`](file:///c:/NIE/NIE_7th_SEM/LOW_POWER_VLSI/Project/research/figures/fig14_ablation_comparison.png) | Architectural ablation study across 6 design configurations ($0\%$ to $44.2\%$). |

---

## 3. Recommended Primary Research Architecture

**Title:** *Uncertainty-Aware and Workload-Adaptive Closed-Loop Adaptive Voltage Scaling with Transient-Constrained Timing Safety in SkyWater 130nm CMOS (UWA-AVS)*

**Target Publication Venues:**
1. **IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems (TCAD)**
2. **IEEE Transactions on Circuits and Systems I: Regular Papers (TCAS-I)**
3. **IEEE International Symposium on Low Power Electronics and Design (ISLPED)**
