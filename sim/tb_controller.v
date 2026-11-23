// ==============================================================================
// Testbench: tb_controller.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Exhaustive verification testbench for AVS Controller FSM (Phase G).
//              Tests:
//              1. Boot-up initialization to safe V_MAX (5'd31) and slew lock
//              2. Stepping down under excessive margin (margin = 5, activity_burst = 0)
//              3. Activity-conditioned downscale gating (activity_burst = 1 inhibits downscale)
//              4. Release of downscale gating when activity_burst returns to 0
//              5. Stepping up under deficit margin (margin = 1) even with burst active
//              6. Deadband lock and assertion of `settled` flag
//              7. Emergency fallback jump to 5'd31 upon margin == 0 hazard
//              8. Manual override mode verification
// ==============================================================================

`timescale 1ns / 1ps

module tb_controller;

    reg        clk_ctrl;
    reg        rst_n;
    reg        avs_enable;
    reg        activity_burst;
    reg  [4:0] manual_code;
    reg  [3:0] target_margin;
    reg  [3:0] margin_code_in;

    wire [4:0] v_code;
    wire       timing_hazard;
    wire       settled;
    wire       slew_locked;
    wire       downscale_gated;
    wire [2:0] fsm_state;

    // Instantiate Unit Under Test (UUT)
    avs_controller #(
        .CODE_WIDTH        (5),
        .MARGIN_WIDTH      (4),
        .SLEW_LOCK_CYCLES  (2),
        .SETTLE_CYCLES     (8), // Reduced to 8 for faster simulation
        .V_MIN             (5'd0),
        .V_MAX             (5'd31),
        .V_INIT            (5'd31)
    ) uut (
        .clk_ctrl          (clk_ctrl),
        .rst_n             (rst_n),
        .avs_enable        (avs_enable),
        .activity_burst    (activity_burst),
        .manual_code       (manual_code),
        .target_margin     (target_margin),
        .margin_code_in    (margin_code_in),
        .v_code            (v_code),
        .timing_hazard     (timing_hazard),
        .settled           (settled),
        .slew_locked       (slew_locked),
        .downscale_gated   (downscale_gated),
        .fsm_state         (fsm_state)
    );

    // Clock Generation: 12.5 MHz Controller Clock (Period = 80.0 ns)
    always #40.0 clk_ctrl = ~clk_ctrl;

    reg [4:0] prev_v_code;

    initial begin
        $dumpfile("sim_controller.vcd");
        $dumpvars(0, tb_controller);

        // Signal initialization
        clk_ctrl       = 0;
        rst_n          = 0;
        avs_enable     = 1;
        activity_burst = 0;
        manual_code    = 5'd15;
        target_margin  = 4'd2; // Target 2 taps of guardband
        margin_code_in = 4'd5; // High initial margin

        $display("------------------------------------------------------------------");
        $display("   TESTBENCH: AVS Controller FSM Verification (Phase G)           ");
        $display("------------------------------------------------------------------");

        // 1. Reset Phase
        #120;
        rst_n = 1;
        $display("[T=%0t] Reset released. Initial v_code = %0d (Expected: 31), slew_locked = %0b",
                 $time, v_code, slew_locked);
        if (v_code !== 5'd31) $fatal(1, "ERROR: Boot voltage code is not V_MAX!");
        if (slew_locked !== 1'b1) $fatal(1, "ERROR: Slew lock not asserted during reset initialization!");

        // Wait for initial slew lock and settle timer
        repeat (12) @(posedge clk_ctrl);
        $display("[T=%0t] Post-boot settle: slew_locked = %0b (Expected: 0)", $time, slew_locked);
        if (slew_locked !== 1'b0) $fatal(1, "ERROR: Slew lock failed to deassert after SLEW_LOCK_CYCLES!");

        // 2. High Margin -> Stepping Down without burst
        // Margin = 5, target = 2, activity_burst = 0. FSM should step DOWN (decrease v_code).
        $display("[T=%0t] Applying margin = 5, burst = 0. Observing standard voltage down-stepping...", $time);
        repeat (30) @(posedge clk_ctrl);
        $display("[T=%0t] v_code after down-step = %0d (State: %0d, downscale_gated: %0b)",
                 $time, v_code, fsm_state, downscale_gated);
        if (v_code >= 5'd31) $fatal(1, "ERROR: FSM failed to decrement voltage code!");
        if (downscale_gated !== 1'b0) $fatal(1, "ERROR: Downscale gating asserted when burst = 0!");

        // 3. Activity-Conditioned Downscale Gating Test
        // Margin = 5 (excessive), but activity_burst = 1. FSM must INHIBIT down-stepping!
        $display("[T=%0t] Activating compute burst (activity_burst = 1). Testing downscale gating...", $time);
        activity_burst = 1;
        repeat (5) @(posedge clk_ctrl);
        prev_v_code = v_code;
        // Run for 30 cycles; during this time downscale_gated must be 1 and v_code must NOT decrease
        repeat (30) @(posedge clk_ctrl);
        $display("[T=%0t] During burst: v_code = %0d (prev: %0d), downscale_gated = %0b, settled = %0b",
                 $time, v_code, prev_v_code, downscale_gated, settled);
        if (v_code < prev_v_code) $fatal(1, "ERROR: Voltage downscaled during active compute burst!");
        if (downscale_gated !== 1'b1) $fatal(1, "ERROR: downscale_gated flag not asserted during burst!");
        if (settled !== 1'b1) $fatal(1, "ERROR: settled flag not maintained during burst hold!");

        // 4. Release Compute Burst (activity_burst = 0)
        // Voltage down-stepping should safely resume
        $display("[T=%0t] Releasing burst (activity_burst = 0). Resuming downscaling...", $time);
        activity_burst = 0;
        repeat (30) @(posedge clk_ctrl);
        $display("[T=%0t] Post-burst v_code = %0d (Expected < %0d), downscale_gated = %0b",
                 $time, v_code, prev_v_code, downscale_gated);
        if (v_code >= prev_v_code) $fatal(1, "ERROR: Downscaling did not resume after burst released!");
        if (downscale_gated !== 1'b0) $fatal(1, "ERROR: downscale_gated remained asserted after burst ended!");

        // 5. Margin reaches target deadband (Margin = 2)
        margin_code_in = 4'd2;
        $display("[T=%0t] Applying target margin = 2. Verifying deadband settling...", $time);
        repeat (20) @(posedge clk_ctrl);
        $display("[T=%0t] Settled flag = %0b, v_code = %0d", $time, settled, v_code);
        if (!settled) $fatal(1, "ERROR: FSM failed to assert settled flag in target window!");

        // 6. Low Margin with Active Burst -> Stepping Up (Safety Override)
        // Up-stepping is NEVER gated even if activity_burst is 1!
        margin_code_in = 4'd1;
        activity_burst = 1;
        prev_v_code    = v_code;
        $display("[T=%0t] Applying deficit margin = 1 with burst = 1. Verifying up-step safety override...", $time);
        repeat (20) @(posedge clk_ctrl);
        $display("[T=%0t] v_code after up-step = %0d (prev: %0d), downscale_gated = %0b",
                 $time, v_code, prev_v_code, downscale_gated);
        if (v_code <= prev_v_code) $fatal(1, "ERROR: Safety up-stepping failed or was blocked by burst!");
        activity_burst = 0;

        // 7. Emergency Hazard Test (Margin drops to 0!)
        $display("[T=%0t] CRITICAL EVENT: Injecting margin = 0 (Timing Hazard!)...", $time);
        margin_code_in = 4'd0;
        repeat (12) @(posedge clk_ctrl);
        $display("[T=%0t] Emergency state: timing_hazard = %0b, v_code = %0d, slew_locked = %0b",
                 $time, timing_hazard, v_code, slew_locked);
        if (v_code !== 5'd31) $fatal(1, "ERROR: Emergency fallback failed to jump to V_MAX!");
        if (!timing_hazard) $fatal(1, "ERROR: Timing hazard alarm flag not asserted!");
        if (!slew_locked) $fatal(1, "ERROR: slew_locked flag not asserted during emergency!");

        // 8. Recovery from Emergency
        margin_code_in = 4'd4;
        repeat (25) @(posedge clk_ctrl);
        $display("[T=%0t] Recovered from emergency: timing_hazard = %0b", $time, timing_hazard);

        // 9. Manual Override Mode Test
        $display("[T=%0t] Switching to Manual Override Mode (avs_enable = 0)...", $time);
        avs_enable  = 0;
        manual_code = 5'd18;
        #100;
        $display("[T=%0t] Manual mode: v_code = %0d (Expected: 18)", $time, v_code);
        if (v_code !== 5'd18) $fatal(1, "ERROR: Manual override did not track manual_code!");

        $display("------------------------------------------------------------------");
        $display("   SUCCESS: All Phase G AVS Controller FSM test vectors passed!   ");
        $display("------------------------------------------------------------------");
        $finish;
    end

endmodule
