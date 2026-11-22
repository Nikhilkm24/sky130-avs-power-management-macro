# ==============================================================================
# OpenSTA Post-Route Timing Sign-off Script with Back-Annotated SPEF
# Project: Closed-Loop AVS Power Management Macro on Sky130
# ==============================================================================

set CORNER "TT"
if { [info exists ::env(CORNER)] } {
    set CORNER $::env(CORNER)
}

puts "=================================================================="
puts "  Running Post-Route OpenSTA Sign-off (SPEF Back-Annotated)       "
puts "  Process Corner: $CORNER                                         "
puts "=================================================================="

# 1. Read Technology Liberty Model
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

# 5. Back-Annotate Post-Route Parasitics (SPEF)
puts "------------------------------------------------------------------"
puts "  Annotating Post-Route Interconnect Parasitics (SPEF)...         "
puts "------------------------------------------------------------------"
read_spef pd/results/avs_system_top.spef

# 6. Report Parasitic Annotation Coverage
report_parasitic_annotation

# 7. Post-Route Worst Setup (Max Delay) Path Analysis
puts "------------------------------------------------------------------"
puts "  1. Post-Route Worst Setup (Max Delay) Path Analysis             "
puts "------------------------------------------------------------------"
report_checks -path_delay max -fields {input_pin slew cap net fanout} -digits 3

# 8. Post-Route Worst Hold (Min Delay) Path Analysis
puts "------------------------------------------------------------------"
puts "  2. Post-Route Worst Hold (Min Delay) Path Analysis              "
puts "------------------------------------------------------------------"
report_checks -path_delay min -fields {input_pin slew cap net fanout} -digits 3

# 9. Clock Skew and Arrival Summary
puts "------------------------------------------------------------------"
puts "  3. Post-Route Clock Skew & Insertion Latency Summary            "
puts "------------------------------------------------------------------"
report_clock_skew -digits 3

# 10. Post-Route Slack Summary
puts "------------------------------------------------------------------"
puts "  4. Post-Route Worst Slack Summary                               "
puts "------------------------------------------------------------------"
report_worst_slack -max
report_worst_slack -min

puts "=================================================================="
puts "  Post-Route STA Sign-off for Corner $CORNER Completed!          "
puts "=================================================================="
exit
