# Dump hierarchical nets and pins from linked design
read_liberty sta/libs/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog synth/avs_system_top_netlist.v
link_design avs_system_top

set fp [open "pd/results/opensta_nets.txt" "w"]
foreach net [get_nets -hierarchical *] {
    set net_name [get_full_name $net]
    set pins [get_pins -of_objects $net]
    set pin_names {}
    foreach p $pins {
        lappend pin_names [get_full_name $p]
    }
    set ports [get_ports -of_objects $net]
    set port_names {}
    foreach pt $ports {
        lappend port_names [get_full_name $pt]
    }
    puts $fp "$net_name | [join $pin_names ,] | [join $port_names ,]"
}
close $fp
puts "Nets dump complete!"
exit
