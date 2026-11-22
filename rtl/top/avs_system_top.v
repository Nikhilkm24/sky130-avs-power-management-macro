// ==============================================================================
// Module: avs_system_top.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Top-Level Digital Macro integrating:
//              - AVS Controller FSM (Domain: VDD_1V8)
//              - Critical Path Monitor (Domain: VDD_CORE)
//              - Pipelined MAC Load (Domain: VDD_CORE)
//              - Level Shifters & CDC Synchronizers
// ==============================================================================

`timescale 1ns / 1ps

module avs_system_top #(
    parameter integer CODE_WIDTH   = 5,
    parameter integer MARGIN_WIDTH = 4,
    parameter integer NUM_TAPS     = 8
)(
    // Clock & Reset (1.8V domain)
    input  wire                    clk_io,          // 12.5 - 25 MHz controller clock
    input  wire                    rst_n,           // Asynchronous active-low reset
    
    // Core Clock (Variable-voltage domain)
    input  wire                    clk_core,        // 50 - 100 MHz load clock
    
    // AVS Configuration & Control
    input  wire                    avs_enable,      // 1 = Closed loop tracking, 0 = Manual
    input  wire [CODE_WIDTH-1:0]   manual_code,     // Manual voltage code
    input  wire [MARGIN_WIDTH-1:0] target_margin,   // Target timing margin (default: 2 taps)
    
    // Status & Observability Outputs
    output wire [CODE_WIDTH-1:0]   dac_voltage_code,// 5-bit code to Analog Reference DAC
    output wire                    timing_hazard,   // Emergency hazard alarm
    output wire                    loop_settled,    // Loop locked inside target deadband
    output wire [2:0]              fsm_state_out,   // Controller state
    
    // Digital Load Controls & Data Ports
    input  wire                    load_enable,
    input  wire                    stress_mode,     // Dynamic LFSR activity burst
    input  wire [15:0]             operand_a,
    input  wire [15:0]             operand_b,
    output wire [31:0]             mac_result,
    output wire                    core_activity_pulse
);

    // --------------------------------------------------------------------------
    // Level Shifter: High-to-Low for Control Signals into VDD_CORE
    // --------------------------------------------------------------------------
    wire load_en_core;
    wire stress_core;
    wire [15:0] op_a_core;
    wire [15:0] op_b_core;

    level_shifter_hl #(.WIDTH(1))  u_ls_en   (.in_high(load_enable), .out_low(load_en_core));
    level_shifter_hl #(.WIDTH(1))  u_ls_str  (.in_high(stress_mode), .out_low(stress_core));
    level_shifter_hl #(.WIDTH(16)) u_ls_opa  (.in_high(operand_a),   .out_low(op_a_core));
    level_shifter_hl #(.WIDTH(16)) u_ls_opb  (.in_high(operand_b),   .out_low(op_b_core));

    // --------------------------------------------------------------------------
    // Instantiation: Pipelined MAC Digital Load (VDD_CORE Domain)
    // --------------------------------------------------------------------------
    wire [31:0] mac_result_core;
    wire        activity_pulse_core;

    pipelined_mac_load u_load (
        .clk_core       (clk_core),
        .rst_n          (rst_n),
        .load_enable    (load_en_core),
        .stress_mode    (stress_core),
        .operand_a_in   (op_a_core),
        .operand_b_in   (op_b_core),
        .mac_result_out (mac_result_core),
        .activity_pulse (activity_pulse_core)
    );

    // --------------------------------------------------------------------------
    // Instantiation: Critical Path Monitor (VDD_CORE Domain)
    // --------------------------------------------------------------------------
    wire [MARGIN_WIDTH-1:0] cpm_margin_core;
    wire [NUM_TAPS-1:0]     cpm_thermo_core;
    wire                    cpm_hazard_core;

    critical_path_monitor #(.NUM_TAPS(NUM_TAPS)) u_cpm (
        .clk_core        (clk_core),
        .rst_n           (rst_n),
        .enable          (1'b1),
        .margin_code     (cpm_margin_core),
        .thermometer_raw (cpm_thermo_core),
        .timing_hazard   (cpm_hazard_core)
    );

    // --------------------------------------------------------------------------
    // Level Shifter: Low-to-High for Signals from VDD_CORE into VDD_1V8
    // --------------------------------------------------------------------------
    wire [MARGIN_WIDTH-1:0] cpm_margin_ls;
    wire [31:0]             mac_result_ls;
    wire                    activity_pulse_ls;

    level_shifter_lh #(.WIDTH(MARGIN_WIDTH)) u_ls_cpm  (.in_low(cpm_margin_core),    .out_high(cpm_margin_ls));
    level_shifter_lh #(.WIDTH(32))           u_ls_mac  (.in_low(mac_result_core),    .out_high(mac_result_ls));
    level_shifter_lh #(.WIDTH(1))            u_ls_act  (.in_low(activity_pulse_core),.out_high(activity_pulse_ls));

    assign mac_result          = mac_result_ls;
    assign core_activity_pulse = activity_pulse_ls;

    // --------------------------------------------------------------------------
    // CDC Synchronizer: Safe crossing of CPM margin into Controller Domain
    // --------------------------------------------------------------------------
    wire [MARGIN_WIDTH-1:0] synchronized_margin;

    cdc_synchronizer #(.WIDTH(MARGIN_WIDTH)) u_cdc_margin (
        .dest_clk   (clk_io),
        .dest_rst_n (rst_n),
        .async_in   (cpm_margin_ls),
        .sync_out   (synchronized_margin)
    );

    // --------------------------------------------------------------------------
    // Instantiation: AVS Controller FSM (VDD_1V8 Domain)
    // --------------------------------------------------------------------------
    avs_controller #(
        .CODE_WIDTH    (CODE_WIDTH),
        .MARGIN_WIDTH  (MARGIN_WIDTH),
        .SETTLE_CYCLES (16),
        .V_MIN         (5'd0),
        .V_MAX         (5'd31),
        .V_INIT        (5'd31)
    ) u_ctrl (
        .clk_ctrl       (clk_io),
        .rst_n          (rst_n),
        .avs_enable     (avs_enable),
        .manual_code    (manual_code),
        .target_margin  (target_margin),
        .margin_code_in (synchronized_margin),
        .v_code         (dac_voltage_code),
        .timing_hazard  (timing_hazard),
        .settled        (loop_settled),
        .fsm_state      (fsm_state_out)
    );

endmodule
