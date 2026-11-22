# Batch Parasitic Extraction for Analog Cells
puts "=========================================================="
puts "  MAGIC 8.3 BATCH PARASITIC EXTRACTION (PEX)             "
puts "=========================================================="
puts "Technology: [tech name]"

puts "\n--- Extracting PMOS Pass Device Parasitics ---"
load pmos_pass_2000u.mag
extract all
ext2spice cthresh 0.001
ext2spice -o pmos_pass_magic_pex.spice

puts "\n--- Extracting DAC Resistor Array Parasitics ---"
load dac_5bit_array.mag
extract all
ext2spice cthresh 0.001
ext2spice -o dac_5bit_magic_pex.spice

puts "\nPEX extraction complete."
quit -noprompt
