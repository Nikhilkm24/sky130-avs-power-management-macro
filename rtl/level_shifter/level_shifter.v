// ==============================================================================
// Module: level_shifter.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Behavioral and Structural Wrappers for Sky130 Multi-Voltage
//              Level Shifter Cells:
//              - Low-to-High (VDD_CORE -> VDD_1V8): sky130_fd_sc_hd__lpflow_lsbuf_lh_1
//              - High-to-Low (VDD_1V8 -> VDD_CORE): sky130_fd_sc_hd__lpflow_lsbuf_hl_1
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

// Double-Flop Synchronizer for Asynchronous Clock Domain Crossing (CDC)
module cdc_synchronizer #(
    parameter integer WIDTH = 4
)(
    input  wire             dest_clk,
    input  wire             dest_rst_n,
    input  wire [WIDTH-1:0] async_in,
    output reg  [WIDTH-1:0] sync_out
);
    reg [WIDTH-1:0] sync_stage1;

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
