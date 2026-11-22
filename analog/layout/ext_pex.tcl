
# Magic 8.3 Parasitic Extraction Script
load pmos_pass_2000u
select top cell
extract all
ext2spice lvs
ext2spice cthresh 0.001
ext2spice -o pmos_pass_magic_pex.spice
ext2spice

load dac_5bit_array
select top cell
extract all
ext2spice lvs
ext2spice cthresh 0.001
ext2spice -o dac_5bit_magic_pex.spice
ext2spice
quit -noprompt
