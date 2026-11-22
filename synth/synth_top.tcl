# ==============================================================================
# Yosys Synthesis Script: AVS System Top on Sky130 HD
# ==============================================================================

# 1. Read Verilog RTL source files
read_verilog -sv rtl/level_shifter/level_shifter.v
read_verilog -sv rtl/load/pipelined_mac_load.v
read_verilog -sv rtl/cpm/critical_path_monitor.v
read_verilog -sv rtl/controller/avs_controller.v
read_verilog -sv rtl/top/avs_system_top.v

# 2. Elaborate Design Hierarchy
hierarchy -check -top avs_system_top

# 3. High-level synthesis & optimizations
proc
opt
fsm
opt
wreduce
opt
peepopt
opt_clean

# 4. Arithmetic and Data-path Mapping
techmap
opt

# 5. Technology Mapping to Sky130 HD Standard Cells
dfflibmap -liberty sta/libs/sky130hd_tt.lib
abc -liberty sta/libs/sky130hd_tt.lib

# 6. Clean and Report Statistics
clean
stat -liberty sta/libs/sky130hd_tt.lib

# 7. Write Gate-Level Netlist for STA and Physical Design
write_verilog -noattr synth/avs_system_top_netlist.v
