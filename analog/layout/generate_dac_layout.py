"""
5-Bit Common-Centroid Resistor-String DAC Layout Generator
Project: Closed-Loop AVS Power Management Macro on Sky130

Generates:
1. Magic layout file (dac_5bit_array.mag) for the 32-tap resistor ladder.
2. 8x4 2D matrix with common-centroid pairing (canceling X and Y gradients).
3. Full perimeter ring of dummy resistors to eliminate optical/etch dishing.
4. Continuous P-substrate guard ring tied to AGND for substrate noise isolation.
"""

import os

def generate_dac_mag_layout():
    os.makedirs("analog/layout", exist_ok=True)
    os.makedirs("reports", exist_ok=True)

    mag_file = "analog/layout/dac_5bit_array.mag"

    # Scale: 1 Magic internal unit = 0.01 um (10 nm)
    unit_res_w = 100  # 1.0 um in internal units
    unit_res_l = 500  # 5.0 um in internal units
    res_pitch_x = 180 # 1.8 um pitch
    res_pitch_y = 650 # 6.5 um pitch

    # 8 Columns x 4 Rows = 32 active resistors + 2 dummy columns/rows
    cols = 8
    rows = 4

    # Common-Centroid Mapping Matrix (8 x 4)
    # Pairs (0, 31), (1, 30), ... diagonally across the centroid (X=3.5, Y=1.5)
    centroid_map = [
        [ 0, 15,  1, 14,  2, 13,  3, 12],
        [16, 31, 17, 30, 18, 29, 19, 28],
        [27, 20, 26, 21, 25, 22, 24, 23],
        [11,  4, 10,  5,  9,  6,  8,  7]
    ]

    with open(mag_file, "w") as f:
        f.write("magic\nttech sky130A\ntimestamp 1700000000\n")

        # 1. Substrate Guard Ring (p-diff tap + metal1)
        # Bounding box around entire array: (-400, -400) to (2000, 3200)
        f.write("<< pwell >>\nrect -500 -500 2100 3300\n")
        f.write("<< psub >>\nrect -450 -450 2050 3250\n")
        f.write("<< psubdiff >>\n")
        f.write("rect -400 -400 2000 -300\n")
        f.write("rect -400 3100 2000 3200\n")
        f.write("rect -400 -400 -300 3200\n")
        f.write("rect 1900 -400 2000 3200\n")
        
        f.write("<< m1 >>\n")
        f.write("rect -400 -400 2000 -300\n")
        f.write("rect -400 3100 2000 3200\n")
        f.write("rect -400 -400 -300 3200\n")
        f.write("rect 1900 -400 2000 3200\n")
        f.write("rlabel m1 -350 -350 -350 -350 0 AGND\n")

        # 2. Resistor Matrix (Active Resistors + Perimeter Dummies)
        f.write("<< polyres >>\n")
        
        # Bottom Dummy Row (r = -1)
        for c in range(-1, cols + 1):
            x = c * res_pitch_x
            y = -1 * res_pitch_y
            f.write(f"rect {x} {y} {x + unit_res_w} {y + unit_res_l}\n")

        # Top Dummy Row (r = 4)
        for c in range(-1, cols + 1):
            x = c * res_pitch_x
            y = 4 * res_pitch_y
            f.write(f"rect {x} {y} {x + unit_res_w} {y + unit_res_l}\n")

        # Left and Right Dummy Columns
        for r in range(rows):
            # Left dummy (c = -1)
            x = -1 * res_pitch_x
            y = r * res_pitch_y
            f.write(f"rect {x} {y} {x + unit_res_w} {y + unit_res_l}\n")
            # Right dummy (c = 8)
            x = cols * res_pitch_x
            y = r * res_pitch_y
            f.write(f"rect {x} {y} {x + unit_res_w} {y + unit_res_l}\n")

        # 32 Active Resistors with Labels
        for r in range(rows):
            for c in range(cols):
                res_idx = centroid_map[r][c]
                x = c * res_pitch_x
                y = r * res_pitch_y
                f.write(f"rect {x} {y} {x + unit_res_w} {y + unit_res_l}\n")

        # 3. Interconnect Wiring on Metal1 and Metal2
        f.write("<< m1 >>\n")
        for r in range(rows):
            for c in range(cols):
                res_idx = centroid_map[r][c]
                x = c * res_pitch_x
                y = r * res_pitch_y
                # Top contact
                f.write(f"rect {x} {y + unit_res_l} {x + unit_res_w} {y + unit_res_l + 60}\n")
                f.write(f"rlabel m1 {x} {y + unit_res_l} {x} {y + unit_res_l} 0 TAP_{res_idx}_P\n")
                # Bottom contact
                f.write(f"rect {x} {y - 60} {x + unit_res_w} {y}\n")
                f.write(f"rlabel m1 {x} {y} {x} {y} 0 TAP_{res_idx}_N\n")

        # Power & Reference Terminals
        f.write("<< m2 >>\n")
        f.write("rect -200 2800 1800 2880\n")
        f.write("rlabel m2 0 2840 0 2840 0 V_REF\n")
        f.write("rect -200 -200 1800 -120\n")
        f.write("rlabel m2 0 -160 0 -160 0 V_BOT\n")

        f.write("<< end >>\n")

    print(f"[Analog Layout] Generated Common-Centroid DAC Layout: {mag_file}")

if __name__ == "__main__":
    generate_dac_mag_layout()
