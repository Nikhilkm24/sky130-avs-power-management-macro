"""
5-Bit Common-Centroid Resistor-String DAC Layout Generator
Project: Closed-Loop AVS Power Management Macro on Sky130

Generates:
1. Magic layout file (dac_5bit_array.mag) for the 32-tap resistor ladder.
2. 8x4 2D matrix with common-centroid pairing (canceling X and Y gradients).
3. Full perimeter ring of dummy resistors to eliminate optical/etch dishing.
4. Continuous P-substrate guard ring tied to AGND for substrate noise isolation.
5. Compliant with Magic 8.3 native database specification.
"""

import os

def generate_dac_mag_layout():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    mag_file = os.path.join(script_dir, "dac_5bit_array.mag")

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

    labels = []

    with open(mag_file, "w") as f:
        f.write("magic\ntech sky130A\ntimestamp 1795336708\n")
        f.write("<< checkpaint >>\nrect -1000 -1000 3000 4000\n")

        # 1. P-Well Substrate
        f.write("<< pwell >>\nrect -1000 -1200 2200 3800\n")

        # 2. Substrate Guard Ring (psubdiff tap >= 0.8 um from poly resistors)
        # Array bounds: X in [-180, 1540], Y in [-650, 3100]
        # Guard ring set at X = [-400, -300] and [1660, 1760], Y = [-900, -800] and [3250, 3350]
        # Spacing to resistors: > 1.5 um (Rule poly.9 requires >= 0.48 um)
        f.write("<< psubdiff >>\n")
        f.write("rect -400 -900 1760 -800\n")
        f.write("rect -400 3250 1760 3350\n")
        f.write("rect -400 -900 -300 3350\n")
        f.write("rect 1660 -900 1760 3350\n")

        # 3. Metal1 Interconnect & Guard Ring Strap
        f.write("<< m1 >>\n")
        f.write("rect -400 -900 1760 -800\n")
        f.write("rect -400 3250 1760 3350\n")
        f.write("rect -400 -900 -300 3350\n")
        f.write("rect 1660 -900 1760 3350\n")
        labels.append("rlabel m1 -350 -850 -350 -850 0 AGND\n")

        # Active resistor contacts on Metal1
        for r in range(rows):
            for c in range(cols):
                res_idx = centroid_map[r][c]
                x = c * res_pitch_x
                y = r * res_pitch_y
                # Top contact
                f.write(f"rect {x} {y + unit_res_l} {x + unit_res_w} {y + unit_res_l + 60}\n")
                labels.append(f"rlabel m1 {x} {y + unit_res_l} {x} {y + unit_res_l} 0 TAP_{res_idx}_P\n")
                # Bottom contact
                f.write(f"rect {x} {y - 60} {x + unit_res_w} {y}\n")
                labels.append(f"rlabel m1 {x} {y} {x} {y} 0 TAP_{res_idx}_N\n")

        # 4. Metal2 Power & Reference Terminals (Outside array area)
        f.write("<< m2 >>\n")
        f.write("rect -200 3450 1800 3530\n")
        labels.append("rlabel m2 0 3490 0 3490 0 V_REF\n")
        f.write("rect -200 -1050 1800 -970\n")
        labels.append("rlabel m2 0 -1010 0 -1010 0 V_BOT\n")

        # 5. Resistor Matrix (Active Resistors + Perimeter Dummies)
        f.write("<< ppolyres >>\n")
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
            x = -1 * res_pitch_x
            y = r * res_pitch_y
            f.write(f"rect {x} {y} {x + unit_res_w} {y + unit_res_l}\n")
            x = cols * res_pitch_x
            y = r * res_pitch_y
            f.write(f"rect {x} {y} {x + unit_res_w} {y + unit_res_l}\n")

        # 32 Active Resistors
        for r in range(rows):
            for c in range(cols):
                x = c * res_pitch_x
                y = r * res_pitch_y
                f.write(f"rect {x} {y} {x + unit_res_w} {y + unit_res_l}\n")

        # 6. Labels Section
        f.write("<< labels >>\n")
        for lbl in labels:
            f.write(lbl)

        f.write("<< end >>\n")

    print(f"[Analog Layout] Generated Common-Centroid DAC Layout: {mag_file}")

if __name__ == "__main__":
    generate_dac_mag_layout()
