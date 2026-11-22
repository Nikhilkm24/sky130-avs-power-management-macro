// ==============================================================================
// Testbench: tb_cpm.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Multi-Corner Physical Timing-Aware Critical Path Monitor (CPM) Testbench.
//
// Verification Layers (v1.4.0):
// Layer 1 — Functional Timing-Aware Wavefront Verification:
//   - Tests calibrated propagation delay through 16-stage replica chain and 8 taps.
//   - Verifies monotonic thermometer code response across delay setpoints (Codes 8 down to 0).
//   - Evaluates timing hazard flag assertion strictly when remaining margin is 0.
//   - Confirms measurement strobe (margin_valid) behavior and disable hold.
// ==============================================================================

`timescale 1ns / 1ps

module tb_cpm;

    parameter integer NUM_TAPS = 8;
    parameter real CLK_PERIOD  = 13.333; // 75.0 MHz nominal core clock (13.333 ns)

    reg                 clk_core;
    reg                 rst_n;
    reg                 enable;

    // Default UUT (Nominal Operating Condition: V_CORE ~ 1.20V, Margin = 8)
    wire [3:0]          margin_nom;
    wire [NUM_TAPS-1:0] therm_nom;
    wire                hazard_nom;
    wire                valid_nom;

    critical_path_monitor #(
        .NUM_TAPS         (NUM_TAPS),
        .REPLICA_DELAY_NS (9.500),  // Fast path: arrives well before 13.333 ns
        .TAP_DELAY_NS     (0.180)
    ) dut_nom (
        .clk_core        (clk_core),
        .rst_n           (rst_n),
        .enable          (enable),
        .margin_code     (margin_nom),
        .thermometer_raw (therm_nom),
        .timing_hazard   (hazard_nom),
        .margin_valid    (valid_nom)
    );

    // Target Settled UUT (Target Condition: V_CORE ~ 1.054V, Target Margin = 2)
    // T_rep + 1*T_tap = 13.00 + 0.20 = 13.20 ns <= 13.333 ns -> Tap 0, 1 match -> Margin = 2
    wire [3:0]          margin_target;
    wire [NUM_TAPS-1:0] therm_target;
    wire                hazard_target;
    wire                valid_target;

    critical_path_monitor #(
        .NUM_TAPS         (NUM_TAPS),
        .REPLICA_DELAY_NS (13.000),
        .TAP_DELAY_NS     (0.200)
    ) dut_target (
        .clk_core        (clk_core),
        .rst_n           (rst_n),
        .enable          (enable),
        .margin_code     (margin_target),
        .thermometer_raw (therm_target),
        .timing_hazard   (hazard_target),
        .margin_valid    (valid_target)
    );

    // Timing Deficit / Hazard UUT (Voltage Sag Condition: V_CORE < 0.95V, Margin = 0)
    // T_rep = 13.60 ns > 13.333 ns -> Even Tap 0 cannot arrive before clock edge -> Hazard = 1
    wire [3:0]          margin_hazard;
    wire [NUM_TAPS-1:0] therm_hazard;
    wire                hazard_hazard;
    wire                valid_hazard;

    critical_path_monitor #(
        .NUM_TAPS         (NUM_TAPS),
        .REPLICA_DELAY_NS (13.600),
        .TAP_DELAY_NS     (0.220)
    ) dut_hazard (
        .clk_core        (clk_core),
        .rst_n           (rst_n),
        .enable          (enable),
        .margin_code     (margin_hazard),
        .thermometer_raw (therm_hazard),
        .timing_hazard   (hazard_hazard),
        .margin_valid    (valid_hazard)
    );

    // Clock Generator: 75.0 MHz (Period = 13.333 ns, half-period = 6.6665 ns)
    always #(CLK_PERIOD / 2.0) clk_core = ~clk_core;

    integer pass_count = 0;
    integer test_count = 0;

    task check_condition(input [127:0] test_name, input condition);
        begin
            test_count = test_count + 1;
            if (condition) begin
                $display("[PASS] Test %0d: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s", test_count, test_name);
            end
        end
    endtask

    initial begin
        $display("==================================================================");
        $display("   TESTBENCH: Timing-Aware CPM Physical Delay Line Verification  ");
        $display("   Clock: 75.0 MHz (T_cycle = %0.3f ns)                           ", CLK_PERIOD);
        $display("==================================================================");

        clk_core = 1'b0;
        rst_n    = 1'b0;
        enable   = 1'b0;

        // 1. Reset Test
        #(CLK_PERIOD * 3);
        check_condition("Reset state: margin_nom == 0", margin_nom == 4'd0);
        check_condition("Reset state: timing_hazard == 0", hazard_nom == 1'b0);
        check_condition("Reset state: margin_valid == 0", valid_nom == 1'b0);

        // 2. Release Reset & Enable
        #(CLK_PERIOD);
        rst_n  = 1'b1;
        enable = 1'b1;

        // Allow pipeline settling (launch + propagate + sample + decode)
        repeat (6) @(posedge clk_core);

        // 3. Test Nominal Operating Condition (High Slack)
        $display("[Nominal Model] Thermometer: %b | Margin Code: %0d | Hazard: %b",
                 therm_nom, margin_nom, hazard_nom);
        check_condition("Nominal delay: full wavefront propagated (Margin == 8)", margin_nom == 4'd8);
        check_condition("Nominal delay: timing_hazard deasserted", hazard_nom == 1'b0);
        check_condition("Nominal delay: margin_valid asserted", valid_nom == 1'b1);

        // 4. Test Target Operating Condition (AVS Settled Lock Point)
        $display("[Target Model]  Thermometer: %b | Margin Code: %0d | Hazard: %b",
                 therm_target, margin_target, hazard_target);
        check_condition("Target delay: partial wavefront matched (Margin == 2)", margin_target == 4'd2);
        check_condition("Target delay: timing_hazard deasserted", hazard_target == 1'b0);

        // 5. Test Timing Deficit / Hazard Condition (Replica delay > T_clk)
        $display("[Hazard Model]  Thermometer: %b | Margin Code: %0d | Hazard: %b",
                 therm_hazard, margin_hazard, hazard_hazard);
        check_condition("Excess delay: zero taps reached (Margin == 0)", margin_hazard == 4'd0);
        check_condition("Excess delay: timing_hazard asserted immediately", hazard_hazard == 1'b1);

        // 6. Test Monotonicity property: Nominal Margin > Target Margin > Hazard Margin
        check_condition("Monotonic delay-to-margin order verified",
                        (margin_nom > margin_target) && (margin_target > margin_hazard));

        // 7. Test Monitor Disable
        enable = 1'b0;
        repeat (3) @(posedge clk_core);
        check_condition("Disable: margin_valid deasserted", valid_nom == 1'b0);

        $display("==================================================================");
        $display("   CPM TEST RESULTS: %0d / %0d PASSED                             ", pass_count, test_count);
        $display("==================================================================");

        if (pass_count == test_count) begin
            $display(">>> ALL CPM PHYSICAL TIMING-AWARE TESTS PASSED <<<");
        end else begin
            $display(">>> SOME CPM TESTS FAILED <<<");
            $finish(1);
        end

        $finish;
    end

endmodule
