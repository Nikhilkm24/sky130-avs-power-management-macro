// ==============================================================================
// Module: level_shifter.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Multi-Voltage Level Shifters and Coherent Clock Domain Crossing (CDC).
//
// Submodules:
// 1. level_shifter_lh: Low-to-High (VDD_CORE -> VDD_1V8) level shifter wrapper.
// 2. level_shifter_hl: High-to-Low (VDD_1V8 -> VDD_CORE) level shifter wrapper.
// 3. cdc_gray_synchronizer: 4-bit Gray-code bus synchronizer ensuring glitch-free,
//    coherent margin transfer across the asynchronous clk_core -> clk_ctrl boundary.
// ==============================================================================

`timescale 1ns / 1ps

// Low-to-High Level Shifter (e.g. 0.9V - 1.5V up to 1.8V)
module level_shifter_lh #(
    parameter integer WIDTH = 1
)(
    input  wire [WIDTH-1:0] in_low,
    output wire [WIDTH-1:0] out_high
);
    // Behavioral representation for functional simulation
    // In physical design, this maps to sky130_fd_sc_hd__lpflow_lsbuf_lh_1
    assign #(0.12) out_high = in_low;
endmodule

// High-to-Low Level Shifter (e.g. 1.8V down to 0.9V - 1.5V)
module level_shifter_hl #(
    parameter integer WIDTH = 1
)(
    input  wire [WIDTH-1:0] in_high,
    output wire [WIDTH-1:0] out_low
);
    // Behavioral representation for functional simulation
    // In physical design, this maps to sky130_fd_sc_hd__lpflow_lsbuf_hl_1
    assign #(0.10) out_low = in_high;
endmodule

// ------------------------------------------------------------------------------
// Coherent Gray-Code Bus Synchronizer (CDC)
// Eliminates bit-parallel metastability skew when crossing multi-bit timing
// margin values between clk_core (75 MHz) and clk_ctrl (12.5 MHz).
// ------------------------------------------------------------------------------
module cdc_gray_synchronizer #(
    parameter integer WIDTH = 4
)(
    input  wire             src_clk,
    input  wire             src_rst_n,
    input  wire [WIDTH-1:0] bin_in,      // Binary input in source clock domain
    input  wire             dest_clk,
    input  wire             dest_rst_n,
    output wire [WIDTH-1:0] bin_out      // Coherent binary output in dest clock domain
);

    // 1. Convert Binary to Gray Code in Source Domain
    reg [WIDTH-1:0] gray_src;
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            gray_src <= {WIDTH{1'b0}};
        end else begin
            gray_src <= bin_in ^ (bin_in >> 1);
        end
    end

    // 2. Double-Flop Synchronizer in Destination Domain
    (* keep = "true" *) reg [WIDTH-1:0] gray_sync1;
    (* keep = "true" *) reg [WIDTH-1:0] gray_sync2;

    always @(posedge dest_clk or negedge dest_rst_n) begin
        if (!dest_rst_n) begin
            gray_sync1 <= {WIDTH{1'b0}};
            gray_sync2 <= {WIDTH{1'b0}};
        end else begin
            gray_sync1 <= gray_src;
            gray_sync2 <= gray_sync1;
        end
    end

    // 3. Convert Gray Code back to Binary in Destination Domain
    wire [WIDTH-1:0] bin_decoded;
    assign bin_decoded[3] = gray_sync2[3];
    assign bin_decoded[2] = bin_decoded[3] ^ gray_sync2[2];
    assign bin_decoded[1] = bin_decoded[2] ^ gray_sync2[1];
    assign bin_decoded[0] = bin_decoded[1] ^ gray_sync2[0];

    assign bin_out = bin_decoded;

endmodule

// Backwards-compatible 2-flop synchronizer wrapper
module cdc_synchronizer #(
    parameter integer WIDTH = 4
)(
    input  wire             dest_clk,
    input  wire             dest_rst_n,
    input  wire [WIDTH-1:0] async_in,
    output reg  [WIDTH-1:0] sync_out
);
    (* keep = "true" *) reg [WIDTH-1:0] sync_stage1;

    always @(posedge dest_clk or negedge dest_rst_n) begin
        if (!dest_rst_n) begin
            sync_stage1 <= {WIDTH{1'b0}};
            sync_out    <= {WIDTH{1'b0}};
        end else begin
            sync_stage1 <= async_in;
            sync_out    <= sync_stage1;
        end
    end
endmodule
