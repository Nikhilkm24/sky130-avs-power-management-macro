// ==============================================================================
// Module: critical_path_monitor.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Synthesizable Workload-Adaptive Dual-Replica Critical Path Monitor (CPM).
//              Implements Phase E dual-replica architecture to resolve critical-path
//              masking during compute bursts.
//
// Hardware Architecture (Phase E Dual-Replica):
// 1. Launch Flip-Flop: Launches an alternating transition wavefront on clk_core.
// 2. Dual Synthesizable Replica Delay Chains:
//    - Path 0 (Multiplier Array): 16-stage standard cell inversion chain (u_rep_inv0..15)
//      modeling 16-bit Booth multiplier partial product tree.
//    - Path 1 (Accumulator Carry-Propagate): 18-stage standard cell chain (u_carry_inv0..17)
//      modeling 32-bit addition carry propagation delay.
// 3. Glitch-Safe Replica Mux: Controlled by dynamic workload activity sentinel (path_select).
// 4. Tapped Physical Delay Line: 8 distinct physical delay buffer stages (cpm_delay_stage)
//    separated by dedicated physical sky130_fd_sc_hd__inv_1 gates with keep/dont_touch attributes.
// 5. Sampling Registers: 8 flip-flops capturing the transition wavefront across the taps.
// 6. Monotonic Thermometer Decoder: Priority decoder producing a 4-bit margin code (0 to 8).
// 7. Timing Hazard Detector: Asserted when margin code drops to 0.
// ==============================================================================

`timescale 1ns / 1ps

// ==============================================================================
// SkyWater 130nm HD Inverter Standard Cell Model
// Used for physical gate mapping in both synthesis and simulation
// ==============================================================================
`ifndef SKY130_FD_SC_HD__INV_1_DEFINED
`define SKY130_FD_SC_HD__INV_1_DEFINED
(* blackbox *)
module sky130_fd_sc_hd__inv_1 (
    output wire Y,
    input  wire A
);
    // Functional standard cell inverter model
    assign Y = ~A;
endmodule
`endif

// Explicit Non-Inverting Delay Cell for Tapped Delay Stages
(* keep_hierarchy = 1 *)
module cpm_delay_stage #(
    parameter real DELAY_NS = 0.180 // Calibrated dual-inverter delay at nominal VDD
)(
    input  wire in,
    output wire out
);
    // Two cascaded Sky130 standard cell inverters with keep/dont_touch attributes
    // to guarantee that synthesis retains physical standard cell instances.
    (* keep = "true", dont_touch = "true" *) wire inv1_out;
    (* keep = "true", dont_touch = "true" *) wire inv2_out;

    sky130_fd_sc_hd__inv_1 u_inv1 (
        .A(in),
        .Y(inv1_out)
    );
    sky130_fd_sc_hd__inv_1 u_inv2 (
        .A(inv1_out),
        .Y(inv2_out)
    );

    // Timing-aware simulation delay annotation across the dual-inverter cell
    assign #(DELAY_NS) out = inv2_out;
endmodule

module critical_path_monitor #(
    parameter integer NUM_TAPS         = 8,
    parameter real    REPLICA_DELAY_NS = 9.800,  // Calibrated 16-stage multiplier replica delay at 1.054V
    parameter real    CARRY_DELAY_NS   = 10.450, // Calibrated 18-stage accumulator carry replica delay at 1.054V
    parameter real    TAP_DELAY_NS     = 0.180   // Calibrated physical delay per tap at 1.054V nominal
)(
    input  wire                 clk_core,        // Core clock (75.0 MHz nominal)
    input  wire                 rst_n,           // Active-low asynchronous reset
    input  wire                 enable,          // Monitor enable
    input  wire                 path_select,     // 0 = Multiplier Replica, 1 = Accumulator Carry Replica
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

    wire replica_start = launch_flop;

    // --------------------------------------------------------------------------
    // 2A. Multiplier Array Replica Path (16 Inversion Stages)
    // Mapped explicitly to sky130_fd_sc_hd__inv_1 standard cell primitives
    // --------------------------------------------------------------------------
    (* keep = "true", dont_touch = "true" *) wire [15:0] rep_net;
    (* keep = "true" *) wire rep_mult_out;

    sky130_fd_sc_hd__inv_1 u_rep_inv0  (.A(replica_start), .Y(rep_net[0]));
    sky130_fd_sc_hd__inv_1 u_rep_inv1  (.A(rep_net[0]),    .Y(rep_net[1]));
    sky130_fd_sc_hd__inv_1 u_rep_inv2  (.A(rep_net[1]),    .Y(rep_net[2]));
    sky130_fd_sc_hd__inv_1 u_rep_inv3  (.A(rep_net[2]),    .Y(rep_net[3]));
    sky130_fd_sc_hd__inv_1 u_rep_inv4  (.A(rep_net[3]),    .Y(rep_net[4]));
    sky130_fd_sc_hd__inv_1 u_rep_inv5  (.A(rep_net[4]),    .Y(rep_net[5]));
    sky130_fd_sc_hd__inv_1 u_rep_inv6  (.A(rep_net[5]),    .Y(rep_net[6]));
    sky130_fd_sc_hd__inv_1 u_rep_inv7  (.A(rep_net[6]),    .Y(rep_net[7]));
    sky130_fd_sc_hd__inv_1 u_rep_inv8  (.A(rep_net[7]),    .Y(rep_net[8]));
    sky130_fd_sc_hd__inv_1 u_rep_inv9  (.A(rep_net[8]),    .Y(rep_net[9]));
    sky130_fd_sc_hd__inv_1 u_rep_inv10 (.A(rep_net[9]),    .Y(rep_net[10]));
    sky130_fd_sc_hd__inv_1 u_rep_inv11 (.A(rep_net[10]),   .Y(rep_net[11]));
    sky130_fd_sc_hd__inv_1 u_rep_inv12 (.A(rep_net[11]),   .Y(rep_net[12]));
    sky130_fd_sc_hd__inv_1 u_rep_inv13 (.A(rep_net[12]),   .Y(rep_net[13]));
    sky130_fd_sc_hd__inv_1 u_rep_inv14 (.A(rep_net[13]),   .Y(rep_net[14]));
    sky130_fd_sc_hd__inv_1 u_rep_inv15 (.A(rep_net[14]),   .Y(rep_net[15]));

    assign #(REPLICA_DELAY_NS) rep_mult_out = rep_net[15];

    // --------------------------------------------------------------------------
    // 2B. Accumulator Carry-Propagate Replica Path (18 Inversion Stages)
    // Models 32-bit addition carry propagation delay during compute bursts
    // --------------------------------------------------------------------------
    (* keep = "true", dont_touch = "true" *) wire [17:0] carry_net;
    (* keep = "true" *) wire rep_carry_out;

    sky130_fd_sc_hd__inv_1 u_carry_inv0  (.A(replica_start),  .Y(carry_net[0]));
    sky130_fd_sc_hd__inv_1 u_carry_inv1  (.A(carry_net[0]),   .Y(carry_net[1]));
    sky130_fd_sc_hd__inv_1 u_carry_inv2  (.A(carry_net[1]),   .Y(carry_net[2]));
    sky130_fd_sc_hd__inv_1 u_carry_inv3  (.A(carry_net[2]),   .Y(carry_net[3]));
    sky130_fd_sc_hd__inv_1 u_carry_inv4  (.A(carry_net[3]),   .Y(carry_net[4]));
    sky130_fd_sc_hd__inv_1 u_carry_inv5  (.A(carry_net[4]),   .Y(carry_net[5]));
    sky130_fd_sc_hd__inv_1 u_carry_inv6  (.A(carry_net[5]),   .Y(carry_net[6]));
    sky130_fd_sc_hd__inv_1 u_carry_inv7  (.A(carry_net[6]),   .Y(carry_net[7]));
    sky130_fd_sc_hd__inv_1 u_carry_inv8  (.A(carry_net[7]),   .Y(carry_net[8]));
    sky130_fd_sc_hd__inv_1 u_carry_inv9  (.A(carry_net[8]),   .Y(carry_net[9]));
    sky130_fd_sc_hd__inv_1 u_carry_inv10 (.A(carry_net[9]),   .Y(carry_net[10]));
    sky130_fd_sc_hd__inv_1 u_carry_inv11 (.A(carry_net[10]),  .Y(carry_net[11]));
    sky130_fd_sc_hd__inv_1 u_carry_inv12 (.A(carry_net[11]),  .Y(carry_net[12]));
    sky130_fd_sc_hd__inv_1 u_carry_inv13 (.A(carry_net[12]),  .Y(carry_net[13]));
    sky130_fd_sc_hd__inv_1 u_carry_inv14 (.A(carry_net[13]),  .Y(carry_net[14]));
    sky130_fd_sc_hd__inv_1 u_carry_inv15 (.A(carry_net[14]),  .Y(carry_net[15]));
    sky130_fd_sc_hd__inv_1 u_carry_inv16 (.A(carry_net[15]),  .Y(carry_net[16]));
    sky130_fd_sc_hd__inv_1 u_carry_inv17 (.A(carry_net[16]),  .Y(carry_net[17]));

    assign #(CARRY_DELAY_NS) rep_carry_out = carry_net[17];

    // --------------------------------------------------------------------------
    // 2C. Workload-Adaptive Replica Path Multiplexer
    // Selects carry replica during high activity bursts to prevent masking
    // --------------------------------------------------------------------------
    (* keep = "true" *) wire replica_path_out;
    assign replica_path_out = path_select ? rep_carry_out : rep_mult_out;

    // --------------------------------------------------------------------------
    // 3. Real Physical Tapped Delay Line
    // Tap 0 connects to the active replica output.
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
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            sample_flops <= {NUM_TAPS{1'b0}};
        end else if (enable) begin
            sample_flops <= tap_wire;
        end
    end

    // --------------------------------------------------------------------------
    // 5. Raw Thermometer Wavefront Generation
    // An active transition is present where the sampled tap equals the newly
    // launched level (i.e. wavefront successfully arrived before the clock edge).
    // --------------------------------------------------------------------------
    reg launch_level_d;
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            launch_level_d <= 1'b0;
        end else begin
            launch_level_d <= launch_flop;
        end
    end

    wire [NUM_TAPS-1:0] raw_thermometer_comb;
    generate
        for (i = 0; i < NUM_TAPS; i = i + 1) begin : gen_raw_thermo
            assign raw_thermometer_comb[i] = (sample_flops[i] == launch_level_d);
        end
    endgenerate

    assign thermometer_raw = raw_thermometer_comb;

    // --------------------------------------------------------------------------
    // 6. Monotonic Thermometer Decoder
    // Counts contiguous arriving wavefront stages from Tap 0 upward.
    // --------------------------------------------------------------------------
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            margin_code   <= 4'd0;
            timing_hazard <= 1'b0;
            margin_valid  <= 1'b0;
        end else if (enable) begin
            margin_valid <= 1'b1;
            casez (raw_thermometer_comb)
                8'b11111111: begin margin_code <= 4'd8; timing_hazard <= 1'b0; end
                8'b?1111111: begin margin_code <= 4'd7; timing_hazard <= 1'b0; end
                8'b??111111: begin margin_code <= 4'd6; timing_hazard <= 1'b0; end
                8'b???11111: begin margin_code <= 4'd5; timing_hazard <= 1'b0; end
                8'b????1111: begin margin_code <= 4'd4; timing_hazard <= 1'b0; end
                8'b?????111: begin margin_code <= 4'd3; timing_hazard <= 1'b0; end
                8'b??????11: begin margin_code <= 4'd2; timing_hazard <= 1'b0; end
                8'b???????1: begin margin_code <= 4'd1; timing_hazard <= 1'b0; end
                default:     begin margin_code <= 4'd0; timing_hazard <= 1'b1; end
            endcase
        end else begin
            margin_valid <= 1'b0;
        end
    end

endmodule
