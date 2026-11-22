# ==============================================================================
# OpenSTA Multi-Corner Timing Sign-off Script: AVS System Top
# Corners: TT (1.8V, 25C), SS (1.4V, -40C), FF (1.95V, -40C)
# ==============================================================================

# Default corner: TT
set CORNER "TT"
if { [info exists ::env(CORNER)] } {
    set CORNER $::env(CORNER)
}

puts "=================================================================="
puts "  Running OpenSTA Timing Analysis - Corner: $CORNER"
puts "=================================================================="

# 1. Load Technology Liberty Timing Model
if { $CORNER == "SS" } {
    read_liberty sta/libs/sky130_fd_sc_hd__ss_n40C_1v40.lib
} elseif { $CORNER == "FF" } {
    read_liberty sta/libs/sky130_fd_sc_hd__ff_n40C_1v95.lib
} else {
    read_liberty sta/libs/sky130_fd_sc_hd__tt_025C_1v80.lib
}

# 2. Read Synthesized Gate-Level Netlist
read_verilog synth/avs_system_top_netlist.v

# 3. Link Design Hierarchy
link_design avs_system_top

# 4. Read SDC Timing Constraints
read_sdc sta/sdc/avs_top.sdc

# 5. Timing Analysis & Slack Reports
check_setup
puts "------------------------------------------------------------------"
puts "  1. Worst Setup (Max Delay) Path Analysis"
puts "------------------------------------------------------------------"
report_checks -path_delay max -fields {input_pin slew cap net fanout} -digits 3

puts "------------------------------------------------------------------"
puts "  2. Worst Hold (Min Delay) Path Analysis"
puts "------------------------------------------------------------------"
report_checks -path_delay min -fields {input_pin slew cap net fanout} -digits 3

puts "------------------------------------------------------------------"
puts "  3. Clock Skew and Arrival Summary"
puts "------------------------------------------------------------------"
report_clock_skew -digits 3

puts "------------------------------------------------------------------"
puts "  4. Worst Slack Summary"
puts "------------------------------------------------------------------"
report_worst_slack -max
report_worst_slack -min

puts "=================================================================="
puts "  STA Sign-off for Corner $CORNER Completed Successfully"
puts "=================================================================="
exit
