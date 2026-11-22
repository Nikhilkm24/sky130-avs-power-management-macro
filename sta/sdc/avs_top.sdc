###############################################################################
# SDC Timing Constraints: AVS Power Management Macro on Sky130
# Top-Level Constraints: Dual Asynchronous Clock Domains & Voltage Scaling
###############################################################################

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA

# -----------------------------------------------------------------------------
# 1. Clock Definitions
# -----------------------------------------------------------------------------
# Controller Clock: Domain VDD_1V8, Period = 50.0 ns (20 MHz)
create_clock -name clk_io -period 50.0 [get_ports clk_io]

# Core Datapath Clock: Domain VDD_CORE, Period = 12.5 ns (80 MHz)
create_clock -name clk_core -period 12.5 [get_ports clk_core]

# -----------------------------------------------------------------------------
# 2. Clock Uncertainties, Jitter & Transition
# -----------------------------------------------------------------------------
set_clock_uncertainty -setup 0.35 [get_clocks clk_core]
set_clock_uncertainty -hold  0.15 [get_clocks clk_core]
set_clock_transition 0.15 [get_clocks clk_core]

set_clock_uncertainty -setup 0.50 [get_clocks clk_io]
set_clock_uncertainty -hold  0.20 [get_clocks clk_io]
set_clock_transition 0.25 [get_clocks clk_io]

# -----------------------------------------------------------------------------
# 3. Clock Domain Crossing (CDC) Asynchronous Grouping
# -----------------------------------------------------------------------------
set_clock_groups -asynchronous \
    -group [get_clocks clk_io] \
    -group [get_clocks clk_core]

# Restrict maximum datapath delay across CDC synchronizer flops
set_max_delay 10.0 -from [get_cells u_cpm/margin_code_reg*] -to [get_cells u_cdc_margin/sync_stage1_reg*] -datapath_only

# -----------------------------------------------------------------------------
# 4. Input / Output Delays & Constraints
# -----------------------------------------------------------------------------
# Controller domain I/O delays
set_input_delay  -clock clk_io -max 5.0 [get_ports {avs_enable manual_code* target_margin*}]
set_input_delay  -clock clk_io -min 1.0 [get_ports {avs_enable manual_code* target_margin*}]
set_output_delay -clock clk_io -max 5.0 [get_ports {dac_voltage_code* timing_hazard loop_settled fsm_state_out*}]
set_output_delay -clock clk_io -min 1.0 [get_ports {dac_voltage_code* timing_hazard loop_settled fsm_state_out*}]

# Core domain I/O delays
set_input_delay  -clock clk_core -max 2.0 [get_ports {load_enable stress_mode operand_a* operand_b*}]
set_input_delay  -clock clk_core -min 0.5 [get_ports {load_enable stress_mode operand_a* operand_b*}]
set_output_delay -clock clk_core -max 2.5 [get_ports {mac_result* core_activity_pulse}]
set_output_delay -clock clk_core -min 0.5 [get_ports {mac_result* core_activity_pulse}]

# Drive and Load Constraints
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 [all_inputs]
set_load 0.05 [all_outputs]
