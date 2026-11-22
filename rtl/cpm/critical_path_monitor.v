// ==============================================================================
// Module: critical_path_monitor.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Replica Critical Path Monitor (CPM).
//              Mirrors the critical path delay of the 16-bit MAC datapath.
//              Contains a tapped delay line with sampling flip-flops to produce
//              a real-time thermometer margin code indicating timing slack.
// ==============================================================================

`timescale 1ns / 1ps

module critical_path_monitor #(
    parameter integer NUM_TAPS = 8
)(
    input  wire                 clk_core,      // Core clock (50 - 100 MHz)
    input  wire                 rst_n,         // Active-low asynchronous reset
    input  wire                 enable,        // Monitor enable
    output reg  [3:0]           margin_code,   // Encoded slack margin (0 to NUM_TAPS)
    output wire [NUM_TAPS-1:0]  thermometer_raw,// Raw sampled taps
    output reg                  timing_hazard  // Asserted if margin drops to 0 (timing hazard)
);

    // Launch flip-flop generates alternating edge transition
    reg launch_flop;
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            launch_flop <= 1'b0;
        end else if (enable) begin
            launch_flop <= ~launch_flop;
        end
    end

    // --------------------------------------------------------------------------
    // Replica Critical-Path Delay Segment
    // Synthesized chain matching the logic topology of a 16-bit multiplier path:
    // XOR gate -> AND/OR tree -> 4-bit ripple full adders
    // --------------------------------------------------------------------------
    wire replica_start;
    assign replica_start = launch_flop;

    wire [7:0] chain_net;
    // Series of delay elements simulating combinational path gates
    assign #(0.6) chain_net[0] = ~replica_start;
    assign #(0.6) chain_net[1] = ~chain_net[0];
    assign #(0.6) chain_net[2] = ~chain_net[1];
    assign #(0.6) chain_net[3] = ~chain_net[2];
    assign #(0.6) chain_net[4] = ~chain_net[3];
    assign #(0.6) chain_net[5] = ~chain_net[4];
    assign #(0.6) chain_net[6] = ~chain_net[5];
    assign #(0.6) chain_net[7] = ~chain_net[6];

    wire replica_path_out;
    assign replica_path_out = chain_net[7];

    // --------------------------------------------------------------------------
    // Tapped Delay Line: 8 successive delay buffers extending past nominal path
    // Each tap represents approximately 150 ps of delay guard-band
    // --------------------------------------------------------------------------
    wire [NUM_TAPS-1:0] tap_wire;
    assign #(0.15) tap_wire[0] = replica_path_out;
    genvar i;
    generate
        for (i = 1; i < NUM_TAPS; i = i + 1) begin : gen_delay_taps
            assign #(0.15) tap_wire[i] = tap_wire[i-1];
        end
    endgenerate

    // --------------------------------------------------------------------------
    // Sampling Flip-Flops: Capture the wavefront on the rising clock edge
    // --------------------------------------------------------------------------
    reg [NUM_TAPS-1:0] sample_flops;
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            sample_flops <= {NUM_TAPS{1'b0}};
        end else begin
            sample_flops <= tap_wire;
        end
    end

    // Detect matched transition wavefront (XOR with expected launch polarity)
    wire [NUM_TAPS-1:0] tap_match;
    generate
        for (i = 0; i < NUM_TAPS; i = i + 1) begin : gen_tap_match
            assign tap_match[i] = (sample_flops[i] == launch_flop);
        end
    endgenerate

    assign thermometer_raw = tap_match;

    // --------------------------------------------------------------------------
    // Thermometer-to-Binary Priority Encoder:
    // Counts consecutive matched taps to report timing margin.
    // --------------------------------------------------------------------------
    integer k;
    reg [3:0] margin_count;

    always @(*) begin
        margin_count = 4'd0;
        for (k = 0; k < NUM_TAPS; k = k + 1) begin
            if (tap_match[k]) begin
                margin_count = margin_count + 4'd1;
            end
        end
    end

    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            margin_code   <= 4'd0;
            timing_hazard <= 1'b0;
        end else begin
            margin_code   <= margin_count;
            // Timing hazard asserted if margin count is 0 (delay exceeded clock period)
            timing_hazard <= (margin_count == 4'd0);
        end
    end

endmodule
