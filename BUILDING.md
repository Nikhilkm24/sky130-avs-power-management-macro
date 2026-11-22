# Building and Toolchain Setup Guide

This guide provides instructions for setting up the required open-source Electronic Design Automation (EDA) toolchain, installing dependencies, configuring environments, and executing build targets for the **Sky130 Adaptive Voltage Scaling (AVS) Power Management Macro**.

---

## 1. System Requirements & Recommended Environment

This project targets open-source silicon toolchains running on **Linux** (native or via Windows Subsystem for Linux - WSL2).

| Component | Specification |
|---|---|
| **Operating System** | Ubuntu 22.04 LTS or Ubuntu 24.04 LTS (recommended: WSL2 on Windows 11) |
| **Processor** | x86_64 or ARM64 multi-core processor (4+ cores recommended) |
| **RAM** | 8 GB minimum (16 GB recommended for full physical design and SPEF extraction) |
| **Disk Space** | ~15 GB free space (including SkyWater 130nm PDK and standard cell libraries) |

---

## 2. Toolchain Inventory & Required Versions

The complete flow uses the following verified open-source tools:

| Tool | Role in Flow | Minimum Version | Tested Version |
|---|---|---|---|
| **Icarus Verilog (`iverilog`)** | Digital RTL simulation & testbench execution | 11.0 | 12.0 (devel) |
| **VVP (`vvp`)** | Icarus Verilog runtime simulation engine | 11.0 | 12.0 (devel) |
| **ngspice** | Transistor-level analog circuit SPICE simulation | 36 | 42 |
| **Yosys** | Open-source RTL synthesis targeting Sky130 HD | 0.30 | 0.36 |
| **OpenSTA (`sta`)** | Static Timing Analysis engine for multi-corner sign-off | 2.4 | 2.6 |
| **Magic VLSI** | Layout generation, Design Rule Checking (DRC), PEX | 8.3.300 | 8.3.450 |
| **Netgen** | Layout Versus Schematic (LVS) netlist comparison | 1.5.200 | 1.5.260 |
| **Python** | Simulation orchestration, modeling, and data analytics | 3.10 | 3.12 |
| **Git** | Version control and workflow management | 2.34 | 2.43 |

---

## 3. Toolchain Installation on Ubuntu / WSL2

Execute the following commands in an Ubuntu terminal (or inside WSL2):

### Step 3.1: Install Base Packages & Compilers
```bash
sudo apt-get update && sudo apt-get install -y \
    build-essential \
    git \
    cmake \
    clang \
    bison \
    flex \
    libreadline-dev \
    gawk \
    tcl-dev \
    tk-dev \
    libffi-dev \
    graphviz \
    xdot \
    pkg-config \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    curl
```

### Step 3.2: Install Digital & Analog Simulation Tools
```bash
# Install Icarus Verilog and runtime
sudo apt-get install -y iverilog

# Install ngspice for analog simulation
sudo apt-get install -y ngspice
```

### Step 3.3: Install Synthesis & Timing Sign-off Tools
```bash
# Install Yosys synthesis engine
sudo apt-get install -y yosys

# Install OpenSTA static timing engine
# Note: In Ubuntu 24.04 or through pre-built packages:
sudo apt-get install -y opensta || {
    echo "Building OpenSTA from source..."
    git clone --recursive https://github.com/The-OpenROAD-Project/OpenSTA.git /tmp/OpenSTA
    mkdir /tmp/OpenSTA/build && cd /tmp/OpenSTA/build
    cmake .. && make -j$(nproc) && sudo make install
}
```

### Step 3.4: Install Magic VLSI and Netgen (Physical Verification)
```bash
sudo apt-get install -y magic netgen
```

---

## 4. Python Environment Setup

The repository relies on Python for high-level closed-loop modeling, PVT matrix generation, DRC/LVS parsing, and energy analytics.

```bash
# Clone the repository (if not already done)
git clone https://github.com/Nikhilkm24/sky130-avs-power-management-macro.git
cd sky130-avs-power-management-macro

# Create an isolated virtual environment
python3 -m venv .venv

# Activate the virtual environment
# On Linux / WSL2:
source .venv/bin/activate
# On Windows PowerShell:
# .\.venv\Scripts\Activate.ps1

# Upgrade pip and install required libraries
pip install --upgrade pip
pip install numpy scipy pandas matplotlib seaborn ipykernel
```

---

## 5. SkyWater 130nm PDK Configuration

The timing and physical design flows reference the SkyWater 130nm high-density (`sky130_fd_sc_hd`) standard cell library.

### PDK Environment Variables
Set the `PDK_ROOT` environment variable in your shell profile (`~/.bashrc` or `~/.profile`):
```bash
export PDK_ROOT=/usr/local/share/pdk
export PDK=sky130A
```

If using a custom local directory:
```bash
export PDK_ROOT=$HOME/pdk
```

---

## 6. Build Targets and Execution Guide

The repository includes a comprehensive `Makefile` providing both domain-specific targets and standard development aliases.

### Primary Engineering Targets

| Target | Command | Description |
|---|---|---|
| **Simulate RTL** | `make sim` | Compiles and executes digital testbenches using `iverilog` & `vvp` (`tb_controller.v`, `tb_avs_top.v`). |
| **Simulate Analog** | `make analog` | Runs `ngspice` batch simulations for BGR, DAC linearity, and LDO regulation. |
| **Synthesize RTL** | `make synth` | Runs `yosys` synthesis targeting `sky130_fd_sc_hd` standard cells. |
| **Static Timing** | `make sta` | Performs pre-route multi-corner OpenSTA timing analysis (TT, SS, FF). |
| **Physical Design** | `make pd` | Executes floorplanning, power distribution, placement, CTS, routing, and SPEF extraction. |
| **Post-Route STA** | `make post_route_sta` | Performs post-route OpenSTA sign-off with SPEF parasitic back-annotation. |
| **Layout Generation**| `make layout` | Generates Magic layout cells (`dac_5bit_array.mag`, `pmos_pass_2000u.mag`). |
| **Design Rule Check**| `make drc` | Executes Magic DRC script and reports violation count. |
| **Layout vs Schem**  | `make lvs` | Runs Netgen LVS comparing extracted netlist to SPICE schematic. |
| **Parasitic Extract**| `make pex` | Extracts parasitic RC network from analog layouts for post-layout simulation. |
| **Closed-Loop Co-Sim**| `make model` | Runs closed-loop dynamic AVS simulation and produces transient performance plots. |
| **PVT Matrix Report**| `make pvt_matrix` | Displays 6-corner PVT sign-off summary matrix. |
| **Energy Curves**    | `make energy_curves` | Generates energy-per-operation vs supply voltage trade-off curves. |
| **Complete Pipeline**| `make all` | Executes the complete end-to-end flow from RTL to sign-off. |
| **Validation Gate**  | `make validate` | Runs all validation stages and outputs sign-off confirmation. |

### Top-10 Standard Development Aliases

| Target | Command | Description |
|---|---|---|
| **`make test`** | `make test` | Fast regression testing: runs RTL simulation testbenches and closed-loop model. |
| **`make lint`** | `make lint` | RTL syntax and linting checks using `iverilog -Wall`. |
| **`make check`** | `make check` | Quick sanity validation combining RTL simulation, model checks, and PVT matrix review. |
| **`make build`** | `make build` | Synthesizes digital macro and builds physical design database (`synth` + `pd`). |
| **`make report`** | `make report` | Displays sign-off metrics and PVT cross-corner summary report. |
| **`make clean`** | `make clean` | Removes generated waveform files (`*.vcd`, `*.vvp`), temporary simulation logs, and caches. |

---

## 7. Verifying a Clean Fresh Setup

To verify that your environment is properly configured, run the following fast verification sequence:

```bash
# 1. Verify digital simulation
make sim

# 2. Verify closed-loop behavioral model
make model

# 3. Verify PVT matrix output
make pvt_matrix

# 4. Run quick sanity check
make check
```

If all commands complete with zero errors, your environment is ready for development.

---

## 8. Troubleshooting Common Issues

### Issue 1: `iverilog: command not found`
- **Cause**: Icarus Verilog is not installed or not in `$PATH`.
- **Solution**: Run `sudo apt-get install -y iverilog` in Ubuntu/WSL2.

### Issue 2: `sta: command not found`
- **Cause**: OpenSTA binary is not in `$PATH`.
- **Solution**: Install OpenROAD/OpenSTA or add its install directory (e.g., `/usr/local/bin`) to your `$PATH`.

### Issue 3: Python `ModuleNotFoundError: No module named 'numpy'`
- **Cause**: Virtual environment is not activated or packages are missing.
- **Solution**: Ensure your virtual environment is active (`source .venv/bin/activate`) and run `pip install -r requirements.txt` (or install `numpy scipy pandas matplotlib seaborn`).

### Issue 4: Magic GUI fails in WSL2
- **Cause**: Missing X11 display server or Wayland configuration.
- **Solution**: The build scripts use batch mode (`magic -dnull -noconsole`). No GUI display server is required for automated layout generation or DRC checks.
