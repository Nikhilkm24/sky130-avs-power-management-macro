# Batch Extraction for LVS Netlist Generation
puts "=========================================================="
puts "  MAGIC 8.3 BATCH EXTRACTION FOR LVS SIGN-OFF             "
puts "=========================================================="
puts "Technology: [tech name]"

puts "\n--- Extracting Cell 1: dac_5bit_array.mag ---"
load dac_5bit_array.mag
extract all
ext2spice lvs
ext2spice -o dac_5bit_array.ext.spice

puts "\n--- Extracting Cell 2: pmos_pass_2000u.mag ---"
load pmos_pass_2000u.mag
extract all
ext2spice lvs
ext2spice -o pmos_pass_2000u.ext.spice

puts "\nMagic extraction complete."
quit -noprompt
