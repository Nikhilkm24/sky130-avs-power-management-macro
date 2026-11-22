// ==============================================================================
// Testbench: tb_avs_top.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Integrated System-Level Digital Testbench.
//              Simulates the closed loop between the controller, level shifters,
//              CPM, and pipelined MAC load under both idle and stress activity bursts.
// ==============================================================================

`timescale 1ns / 1ps

module tb_avs_top;

    reg         clk_io;
    reg         clk_core;
    reg         rst_n;
    reg         avs_enable;
    reg  [4:0]  manual_code;
    reg  [3:0]  target_margin;
    reg         load_enable;
    reg         stress_mode;
    reg  [15:0] operand_a;
    reg  [15:0] operand_b;

    wire [4:0]  dac_voltage_code;
    wire        timing_hazard;
    wire        loop_settled;
    wire [2:0]  fsm_state_out;
    wire [31:0] mac_result;
    wire        core_activity_pulse;
    wire        cpm_path_select;

    // Instantiate UUT Top-Level
    avs_system_top #(
        .CODE_WIDTH   (5),
        .MARGIN_WIDTH (4),
        .NUM_TAPS     (8)
    ) uut_top (
        .clk_io              (clk_io),
        .rst_n               (rst_n),
        .clk_core            (clk_core),
        .avs_enable          (avs_enable),
        .manual_code         (manual_code),
        .target_margin       (target_margin),
        .dac_voltage_code    (dac_voltage_code),
        .timing_hazard       (timing_hazard),
        .loop_settled        (loop_settled),
        .fsm_state_out       (fsm_state_out),
        .load_enable         (load_enable),
        .stress_mode         (stress_mode),
        .operand_a           (operand_a),
        .operand_b           (operand_b),
        .mac_result          (mac_result),
        .core_activity_pulse (core_activity_pulse),
        .cpm_path_select     (cpm_path_select)
    );

    // Clock Generation:
    // clk_io = 12.5 MHz Controller Clock (Period = 80.0 ns)
    always #40.0 clk_io = ~clk_io;

    // clk_core = 75.0 MHz Core Clock (Period = 13.333 ns)
    always #6.6665 clk_core = ~clk_core;

    initial begin
        $dumpfile("sim_avs_top.vcd");
        $dumpvars(0, tb_avs_top);

        clk_io        = 0;
        clk_core      = 0;
        rst_n         = 0;
        avs_enable    = 1;
        manual_code   = 5'd31;
        target_margin = 4'd2;
        load_enable   = 1;
        stress_mode   = 0;
        operand_a     = 16'd12;
        operand_b     = 16'd8;

        $display("==================================================================");
        $display("   TESTBENCH: Integrated AVS Digital Top-Level System             ");
        $display("==================================================================");

        #150;
        rst_n = 1;
        $display("[T=%0t] System reset released.", $time);

        // Run computation with idle activity
        repeat (100) @(posedge clk_core);
        $display("[T=%0t] MAC Result (Idle mode): 0x%08h | DAC Voltage Code = %0d | CPM Path Select = %0b",
                 $time, mac_result, dac_voltage_code, cpm_path_select);
        if (cpm_path_select !== 1'b0) begin
            $display("[FAIL] Expected cpm_path_select == 0 in idle mode, got %0b", cpm_path_select);
            $finish(1);
        end

        // Trigger dynamic stress mode (high activity burst)
        $display("[T=%0t] Activating STRESS MODE (pseudo-random LFSR burst)...", $time);
        stress_mode = 1;
        repeat (10) @(posedge clk_core);
        if (cpm_path_select !== 1'b1) begin
            $display("[FAIL] Expected cpm_path_select == 1 in stress mode, got %0b", cpm_path_select);
            $finish(1);
        end
        $display("[T=%0t] Sentinel Verified: cpm_path_select successfully switched to carry replica (%0b)",
                 $time, cpm_path_select);
        repeat (190) @(posedge clk_core);
        $display("[T=%0t] MAC Result (Stress mode): 0x%08h | Loop Settled = %0b",
                 $time, mac_result, loop_settled);

        // De-stress
        stress_mode = 0;
        repeat (150) @(posedge clk_core);
        $display("[T=%0t] Deactivated stress mode. Final DAC code = %0d | CPM Path Select = %0b",
                 $time, dac_voltage_code, cpm_path_select);
        if (cpm_path_select !== 1'b0) begin
            $display("[FAIL] Expected cpm_path_select == 0 after decay window, got %0b", cpm_path_select);
            $finish(1);
        end
        $display("[T=%0t] Sentinel Verified: cpm_path_select safely returned to multiplier replica (%0b)",
                 $time, cpm_path_select);

        $display("==================================================================");
        $display("   SUCCESS: Integrated AVS top-level simulation completed!        ");
        $display("==================================================================");
        $finish;
    end

endmodule
