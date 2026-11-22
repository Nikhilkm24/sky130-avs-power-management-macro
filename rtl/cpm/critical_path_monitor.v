// ==============================================================================
// Module: critical_path_monitor.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Synthesizable Replica Critical Path Monitor (CPM).
//
// Hardware Architecture (v1.3.0 Redesign):
// 1. Launch Flip-Flop: Launches a clean transition edge on every core clock cycle.
// 2. Replica Path: 16-stage inversion chain modeling critical path gate delay.
// 3. Physical Tapped Delay Line: 8 distinct, physical delay buffer stages
//    placed in series after the replica path. Every tap is separated by an
//    explicit, non-collapsible delay element with keep/dont_touch attributes.
// 4. Sampling Registers: Bank of 8 flip-flops clocked by clk_core capturing
//    the propagating transition wavefront across the taps at the cycle boundary.
// 5. Monotonic Thermometer Decoder: Priority decoder producing a 4-bit margin
//    code (0 to 8) representing quantized timing slack.
// 6. Timing Hazard Detector: Asserted when margin code drops to 0.
// ==============================================================================

`timescale 1ns / 1ps

// Explicit Non-Inverting Delay Cell for Tapped Delay Stages
module cpm_delay_stage (
    input  wire in,
    output wire out
);
    // Two cascaded inverters with keep/dont_touch attributes to prevent
    // logic synthesis from pruning or merging consecutive taps.
    (* keep = "true", dont_touch = "true" *) wire inv1_out;
    (* keep = "true", dont_touch = "true" *) wire inv2_out;

    assign inv1_out = ~in;
    assign inv2_out = ~inv1_out;
    assign out      = inv2_out;
endmodule

module critical_path_monitor #(
    parameter integer NUM_TAPS = 8
)(
    input  wire                 clk_core,        // Core clock (75.0 MHz nominal)
    input  wire                 rst_n,           // Active-low asynchronous reset
    input  wire                 enable,          // Monitor enable
    output reg  [3:0]           margin_code,     // Encoded timing margin (0 to NUM_TAPS)
    output wire [NUM_TAPS-1:0]  thermometer_raw, // Raw sampled wavefront taps
    output reg                  timing_hazard    // Asserted when margin code == 0
);

    // --------------------------------------------------------------------------
    // 1. Launch Flip-Flop
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

    assign rep_net[0]  = ~replica_start;
    assign rep_net[1]  = ~rep_net[0];
    assign rep_net[2]  = ~rep_net[1];
    assign rep_net[3]  = ~rep_net[2];
    assign rep_net[4]  = ~rep_net[3];
    assign rep_net[5]  = ~rep_net[4];
    assign rep_net[6]  = ~rep_net[5];
    assign rep_net[7]  = ~rep_net[6];
    assign rep_net[8]  = ~rep_net[7];
    assign rep_net[9]  = ~rep_net[8];
    assign rep_net[10] = ~rep_net[9];
    assign rep_net[11] = ~rep_net[10];
    assign rep_net[12] = ~rep_net[11];
    assign rep_net[13] = ~rep_net[12];
    assign rep_net[14] = ~rep_net[13];
    assign rep_net[15] = ~rep_net[14];

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
            cpm_delay_stage u_stage (
                .in  (tap_wire[i-1]),
                .out (tap_wire[i])
            );
        end
    endgenerate

    // --------------------------------------------------------------------------
    // 4. Sampling Registers: Capture wavefront on rising edge of clk_core
    // --------------------------------------------------------------------------
    reg [NUM_TAPS-1:0] sample_flops;
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            sample_flops <= {NUM_TAPS{1'b0}};
        end else begin
            sample_flops <= tap_wire;
        end
    end

    // Detect matched transition wavefront against current launched polarity
    wire [NUM_TAPS-1:0] tap_match;
    generate
        for (i = 0; i < NUM_TAPS; i = i + 1) begin : gen_tap_match
            assign tap_match[i] = (sample_flops[i] == launch_flop);
        end
    endgenerate

    assign thermometer_raw = tap_match;

    // --------------------------------------------------------------------------
    // 5. Monotonic Priority Thermometer Decoder
    // Counts contiguous transition matches from tap 0 upwards.
    // --------------------------------------------------------------------------
    reg [3:0] margin_decoded;
    always @(*) begin
        casez (tap_match)
            8'b1111_1111: margin_decoded = 4'd8;
            8'b?111_1111: margin_decoded = 4'd7;
            8'b??11_1111: margin_decoded = 4'd6;
            8'b???1_1111: margin_decoded = 4'd5;
            8'b????_1111: margin_decoded = 4'd4;
            8'b????_?111: margin_decoded = 4'd3;
            8'b????_??11: margin_decoded = 4'd2;
            8'b????_???1: margin_decoded = 4'd1;
            default:      margin_decoded = 4'd0;
        endcase
    end

    // --------------------------------------------------------------------------
    // 6. Registered Output and Timing Hazard Flag
    // --------------------------------------------------------------------------
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            margin_code   <= 4'd0;
            timing_hazard <= 1'b0;
        end else begin
            margin_code   <= margin_decoded;
            timing_hazard <= (margin_decoded == 4'd0);
        end
    end

endmodule
