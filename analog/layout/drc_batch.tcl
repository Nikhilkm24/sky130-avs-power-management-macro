# Batch DRC Script for Sky130 Analog Layouts
puts "=========================================================="
puts "  MAGIC 8.3 BATCH DRC: CLOSED-LOOP AVS POWER MACRO       "
puts "=========================================================="
puts "Technology: [tech name]"

# 1. Audit DAC Resistor Array
puts "\n--- Auditing Cell 1: dac_5bit_array.mag ---"
load dac_5bit_array.mag
drc check
drc catchup
set dac_errors [drc list count total]
puts "CELL: dac_5bit_array"
puts "DRC_ERRORS: $dac_errors"
if {$dac_errors > 0} {
    puts "DRC Violations in dac_5bit_array:"
    set errs [drc listall why]
    foreach {err list} $errs {
        puts "  Rule: $err (Count: [llength $list])"
    }
} else {
    puts "  PASS: dac_5bit_array is 100% DRC clean."
}

# 2. Audit PMOS Pass Transistor
puts "\n--- Auditing Cell 2: pmos_pass_2000u.mag ---"
load pmos_pass_2000u.mag
drc check
drc catchup
set pmos_errors [drc list count total]
puts "CELL: pmos_pass_2000u"
puts "DRC_ERRORS: $pmos_errors"
if {$pmos_errors > 0} {
    puts "DRC Violations in pmos_pass_2000u:"
    set errs [drc listall why]
    foreach {err list} $errs {
        puts "  Rule: $err (Count: [llength $list])"
    }
} else {
    puts "  PASS: pmos_pass_2000u is 100% DRC clean."
}

puts "\n=========================================================="
puts "MAGIC DRC BATCH EXECUTION COMPLETED"
puts "=========================================================="
quit -noprompt
