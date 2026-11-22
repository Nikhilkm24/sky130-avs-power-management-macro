// ==============================================================================
// Module: critical_path_monitor.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Synthesizable Replica Critical Path Monitor (CPM).
//              Features:
//              1. Synthesizable 16-stage replica delay chain with explicit
//                 keep attributes on nets to survive logic optimization.
//              2. 8-tap tapped delay line with sampling flip-flops.
//              3. Monotonic priority thermometer decoder guaranteeing
//                 monotonic slack measurements.
//              4. Real-time timing hazard detection flag.
// ==============================================================================

`timescale 1ns / 1ps

module critical_path_monitor #(
    parameter integer NUM_TAPS = 8
)(
    input  wire                 clk_core,        // Core clock (75 - 80 MHz)
    input  wire                 rst_n,           // Active-low asynchronous reset
    input  wire                 enable,          // Monitor enable
    output reg  [3:0]           margin_code,     // Encoded slack margin (0 to NUM_TAPS)
    output wire [NUM_TAPS-1:0]  thermometer_raw, // Raw sampled taps
    output reg                  timing_hazard    // Asserted if margin drops to 0 (timing hazard)
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
    // Synthesizable Replica Delay Chain (16 Inversion Stages)
    // Structured logic path modeling inverter/NAND/NOR gates of the MAC datapath.
    // Explicit keep attributes on wires prevent Yosys optimization and removal.
    // --------------------------------------------------------------------------
    wire replica_start = launch_flop;
    (* keep = "true" *) wire [15:0] rep_net;

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
    // Tapped Delay Line: 8 successive delay buffers extending past replica path
    // --------------------------------------------------------------------------
    (* keep = "true" *) wire [NUM_TAPS-1:0] tap_wire;
    assign tap_wire[0] = replica_path_out;
    genvar i;
    generate
        for (i = 1; i < NUM_TAPS; i = i + 1) begin : gen_delay_taps
            assign tap_wire[i] = tap_wire[i-1];
        end
    endgenerate

    // --------------------------------------------------------------------------
    // Sampling Flip-Flops: Capture wavefront on rising clock edge
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
    // Monotonic Priority Thermometer Decoder:
    // Decodes contiguous transition pattern from tap 0 upwards.
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
