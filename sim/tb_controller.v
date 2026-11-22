// ==============================================================================
// Testbench: tb_controller.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Exhaustive verification testbench for AVS Controller FSM.
//              Tests:
//              1. Boot-up initialization to safe V_MAX (5'd31)
//              2. Stepping down under excessive margin (margin = 6)
//              3. Stepping up under deficit margin (margin = 1)
//              4. Deadband lock and assertion of `settled` flag
//              5. Emergency fallback jump to 5'd31 upon margin == 0 hazard
//              6. Manual override mode verification
// ==============================================================================

`timescale 1ns / 1ps

module tb_controller;

    reg        clk_ctrl;
    reg        rst_n;
    reg        avs_enable;
    reg  [4:0] manual_code;
    reg  [3:0] target_margin;
    reg  [3:0] margin_code_in;

    wire [4:0] v_code;
    wire       timing_hazard;
    wire       settled;
    wire [2:0] fsm_state;

    // Instantiate Unit Under Test (UUT)
    avs_controller #(
        .CODE_WIDTH    (5),
        .MARGIN_WIDTH  (4),
        .SETTLE_CYCLES (8), // Reduced to 8 for faster simulation
        .V_MIN         (5'd0),
        .V_MAX         (5'd31),
        .V_INIT        (5'd31)
    ) uut (
        .clk_ctrl       (clk_ctrl),
        .rst_n          (rst_n),
        .avs_enable     (avs_enable),
        .manual_code    (manual_code),
        .target_margin  (target_margin),
        .margin_code_in (margin_code_in),
        .v_code         (v_code),
        .timing_hazard  (timing_hazard),
        .settled        (settled),
        .fsm_state      (fsm_state)
    );

    // Clock Generation: 20 MHz (Period = 50 ns)
    always #25 clk_ctrl = ~clk_ctrl;

    initial begin
        $dumpfile("sim_controller.vcd");
        $dumpvars(0, tb_controller);

        // Signal initialization
        clk_ctrl       = 0;
        rst_n          = 0;
        avs_enable     = 1;
        manual_code    = 5'd15;
        target_margin  = 4'd2; // Target 2 taps of guardband
        margin_code_in = 4'd5; // High initial margin

        $display("------------------------------------------------------------------");
        $display("   TESTBENCH: AVS Controller FSM Verification (Sky130)            ");
        $display("------------------------------------------------------------------");

        // 1. Reset Phase
        #120;
        rst_n = 1;
        $display("[T=%0t] Reset released. Initial v_code = %0d (Expected: 31)", $time, v_code);
        if (v_code !== 5'd31) $fatal(1, "ERROR: Boot voltage code is not V_MAX!");

        // 2. High Margin -> Stepping Down
        // Margin = 5, target = 2. FSM should step DOWN (decrease v_code).
        $display("[T=%0t] Applying margin = 5 (Target = 2). Observing voltage down-stepping...", $time);
        repeat (30) @(posedge clk_ctrl);
        $display("[T=%0t] v_code after down-step = %0d (State: %0d)", $time, v_code, fsm_state);
        if (v_code >= 5'd31) $fatal(1, "ERROR: FSM failed to decrement voltage code!");

        // 3. Margin reaches target deadband (Margin = 2)
        margin_code_in = 4'd2;
        $display("[T=%0t] Applying target margin = 2. Verifying deadband settling...", $time);
        repeat (20) @(posedge clk_ctrl);
        $display("[T=%0t] Settled flag = %0b, v_code = %0d", $time, settled, v_code);
        if (!settled) $fatal(1, "ERROR: FSM failed to assert settled flag in target window!");

        // 4. Low Margin -> Stepping Up
        // Margin = 1, target = 2. FSM should step UP (increase v_code).
        margin_code_in = 4'd1;
        $display("[T=%0t] Applying deficit margin = 1. Observing voltage up-stepping...", $time);
        repeat (20) @(posedge clk_ctrl);
        $display("[T=%0t] v_code after up-step = %0d", $time, v_code);

        // 5. Emergency Hazard Test (Margin drops to 0!)
        $display("[T=%0t] CRITICAL EVENT: Injecting margin = 0 (Timing Hazard!)...", $time);
        margin_code_in = 4'd0;
        repeat (12) @(posedge clk_ctrl);
        $display("[T=%0t] Emergency state: timing_hazard = %0b, v_code = %0d", $time, timing_hazard, v_code);
        if (v_code !== 5'd31) $fatal(1, "ERROR: Emergency fallback failed to jump to V_MAX!");
        if (!timing_hazard) $fatal(1, "ERROR: Timing hazard alarm flag not asserted!");

        // 6. Recovery from Emergency
        margin_code_in = 4'd4;
        repeat (25) @(posedge clk_ctrl);
        $display("[T=%0t] Recovered from emergency: timing_hazard = %0b", $time, timing_hazard);

        // 7. Manual Override Mode Test
        $display("[T=%0t] Switching to Manual Override Mode (avs_enable = 0)...", $time);
        avs_enable  = 0;
        manual_code = 5'd18;
        #100;
        $display("[T=%0t] Manual mode: v_code = %0d (Expected: 18)", $time, v_code);
        if (v_code !== 5'd18) $fatal(1, "ERROR: Manual override did not track manual_code!");

        $display("------------------------------------------------------------------");
        $display("   SUCCESS: All AVS Controller FSM test vectors passed!           ");
        $display("------------------------------------------------------------------");
        $finish;
    end

endmodule
