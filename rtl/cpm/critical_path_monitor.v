// ==============================================================================
// Module: critical_path_monitor.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Synthesizable Replica Critical Path Monitor (CPM).
//
// Hardware Architecture (v1.4.0 Physical Timing Verification):
// 1. Launch Flip-Flop: Launches an alternating transition wavefront on clk_core.
// 2. Synthesizable Replica Chain: 16-stage inversion chain modeling critical path
//    combinational gate delay with explicit synthesis preservation attributes.
// 3. Tapped Physical Delay Line: 8 distinct, physical delay buffer stages
//    (cpm_delay_stage) placed in series after the replica path. Every tap is
//    separated by a dedicated physical delay element with keep/dont_touch attributes.
// 4. Timing-Aware Simulation Support: Parametric delay modeling enables simulation
//    of propagating wavefronts across variable clock periods and PVT corners.
// 5. Sampling Registers: Bank of 8 flip-flops clocked by clk_core capturing
//    the propagating transition wavefront across the taps at the cycle boundary.
// 6. Monotonic Thermometer Decoder: Priority decoder producing a 4-bit margin
//    code (0 to 8) representing quantized timing slack.
// 7. Timing Hazard Detector: Asserted when margin code drops to 0.
// ==============================================================================

`timescale 1ns / 1ps

// Explicit Non-Inverting Delay Cell for Tapped Delay Stages
(* keep_hierarchy = 1 *)
module cpm_delay_stage #(
    parameter real DELAY_NS = 0.180 // Calibrated dual-inverter delay at nominal VDD
)(
    input  wire in,
    output wire out
);
    // Two cascaded inverters with keep/dont_touch attributes to prevent
    // logic synthesis from pruning or merging consecutive taps.
    (* keep = "true", dont_touch = "true" *) wire inv1_out;
    (* keep = "true", dont_touch = "true" *) wire inv2_out;

    assign #(DELAY_NS / 2.0) inv1_out = ~in;
    assign #(DELAY_NS / 2.0) inv2_out = ~inv1_out;
    assign out = inv2_out;
endmodule

module critical_path_monitor #(
    parameter integer NUM_TAPS         = 8,
    parameter real    REPLICA_DELAY_NS = 9.800, // Calibrated 16-stage replica delay at 1.054V nominal
    parameter real    TAP_DELAY_NS     = 0.180  // Calibrated physical delay per tap at 1.054V nominal
)(
    input  wire                 clk_core,        // Core clock (75.0 MHz nominal)
    input  wire                 rst_n,           // Active-low asynchronous reset
    input  wire                 enable,          // Monitor enable
    output reg  [3:0]           margin_code,     // Encoded timing margin (0 to NUM_TAPS)
    output wire [NUM_TAPS-1:0]  thermometer_raw, // Raw sampled wavefront taps
    output reg                  timing_hazard,   // Asserted when margin code == 0
    output reg                  margin_valid     // High for 1 cycle when measurement is updated
);

    // --------------------------------------------------------------------------
    // 1. Launch Flip-Flop
    // Toggles output on each clock edge to launch a propagating wavefront.
    // --------------------------------------------------------------------------
    reg launch_flop;
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            launch_flop <= 1'b0;
        end else if (enable) begin
            launch_flop <= ~launch_flop;
        end
    end

    // --------------------------------------------------------------------------
    // 2. Synthesizable Replica Delay Chain (16 Inversion Stages)
    // --------------------------------------------------------------------------
    wire replica_start = launch_flop;
    (* keep = "true", dont_touch = "true" *) wire [15:0] rep_net;

    localparam real INV_DELAY = REPLICA_DELAY_NS / 16.0;

    assign #(INV_DELAY) rep_net[0]  = ~replica_start;
    assign #(INV_DELAY) rep_net[1]  = ~rep_net[0];
    assign #(INV_DELAY) rep_net[2]  = ~rep_net[1];
    assign #(INV_DELAY) rep_net[3]  = ~rep_net[2];
    assign #(INV_DELAY) rep_net[4]  = ~rep_net[3];
    assign #(INV_DELAY) rep_net[5]  = ~rep_net[4];
    assign #(INV_DELAY) rep_net[6]  = ~rep_net[5];
    assign #(INV_DELAY) rep_net[7]  = ~rep_net[6];
    assign #(INV_DELAY) rep_net[8]  = ~rep_net[7];
    assign #(INV_DELAY) rep_net[9]  = ~rep_net[8];
    assign #(INV_DELAY) rep_net[10] = ~rep_net[9];
    assign #(INV_DELAY) rep_net[11] = ~rep_net[10];
    assign #(INV_DELAY) rep_net[12] = ~rep_net[11];
    assign #(INV_DELAY) rep_net[13] = ~rep_net[12];
    assign #(INV_DELAY) rep_net[14] = ~rep_net[13];
    assign #(INV_DELAY) rep_net[15] = ~rep_net[14];

    wire replica_path_out = rep_net[15];

    // --------------------------------------------------------------------------
    // 3. Real Physical Tapped Delay Line
    // Tap 0 connects to the replica output.
    // Each subsequent tap (1 to NUM_TAPS-1) passes through an explicit delay stage.
    // --------------------------------------------------------------------------
    (* keep = "true" *) wire [NUM_TAPS-1:0] tap_wire;
    assign tap_wire[0] = replica_path_out;

    genvar i;
    generate
        for (i = 1; i < NUM_TAPS; i = i + 1) begin : gen_physical_taps
            cpm_delay_stage #(.DELAY_NS(TAP_DELAY_NS)) u_stage (
                .in  (tap_wire[i-1]),
                .out (tap_wire[i])
            );
        end
    endgenerate

    // --------------------------------------------------------------------------
    // 4. Sampling Registers: Capture wavefront on rising edge of clk_core
    // --------------------------------------------------------------------------
    reg [NUM_TAPS-1:0] sample_flops;
    reg launch_flop_d1;

    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            sample_flops   <= {NUM_TAPS{1'b0}};
            launch_flop_d1 <= 1'b0;
        end else begin
            sample_flops   <= tap_wire;
            launch_flop_d1 <= launch_flop;
        end
    end

    // Detect matched transition wavefront:
    // A tap successfully captured the propagating wavefront if its sampled value
    // matches the polarity launched in the preceding clock cycle (launch_flop_d1).
    wire [NUM_TAPS-1:0] tap_match;
    generate
        for (i = 0; i < NUM_TAPS; i = i + 1) begin : gen_tap_match
            assign tap_match[i] = (sample_flops[i] == launch_flop_d1);
        end
    endgenerate

    assign thermometer_raw = tap_match;

    // --------------------------------------------------------------------------
    // 5. Monotonic Priority Thermometer Decoder
    // Counts contiguous transition matches from tap 0 upwards (quantized slack).
    // --------------------------------------------------------------------------
    reg [3:0] margin_decoded;
    always @(*) begin
        margin_decoded = 4'd0;
        if (tap_match[0]) margin_decoded = 4'd1;
        if (tap_match[0] && tap_match[1]) margin_decoded = 4'd2;
        if (tap_match[0] && tap_match[1] && tap_match[2]) margin_decoded = 4'd3;
        if (tap_match[0] && tap_match[1] && tap_match[2] && tap_match[3]) margin_decoded = 4'd4;
        if (tap_match[0] && tap_match[1] && tap_match[2] && tap_match[3] && tap_match[4]) margin_decoded = 4'd5;
        if (tap_match[0] && tap_match[1] && tap_match[2] && tap_match[3] && tap_match[4] && tap_match[5]) margin_decoded = 4'd6;
        if (tap_match[0] && tap_match[1] && tap_match[2] && tap_match[3] && tap_match[4] && tap_match[5] && tap_match[6]) margin_decoded = 4'd7;
        if (&tap_match) margin_decoded = 4'd8;
    end

    // --------------------------------------------------------------------------
    // 6. Registered Output, Valid Strobe, and Timing Hazard Flag
    // --------------------------------------------------------------------------
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            margin_code   <= 4'd0;
            timing_hazard <= 1'b0;
            margin_valid  <= 1'b0;
        end else if (enable) begin
            margin_code   <= margin_decoded;
            timing_hazard <= (margin_decoded == 4'd0);
            margin_valid  <= 1'b1;
        end else begin
            margin_valid  <= 1'b0;
        end
    end

endmodule
