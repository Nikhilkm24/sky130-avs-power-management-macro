// ==============================================================================
// Module: level_shifter.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Multi-Voltage Domain Level Shifters & Coherent Clock Domain Crossing (CDC).
//
// Engineering Implementation (v1.4.0 Protocol Hardening):
// 1. level_shifter_lh: Low-to-High (VDD_CORE -> VDD_1V8) level shifter wrapper.
//    - PDK Mapping: sky130_fd_sc_hd__lpflow_lsbuf_lh_1 (dual-rail standard cell).
//    - Pin Interface: A (low-voltage input), VPWR (1.80V), VMAX (1.80V), VGND, VNB, X.
//    - RTL Abstraction: Synthesizable/behavioral model for functional simulation.
// 2. level_shifter_hl: High-to-Low (VDD_1V8 -> VDD_CORE) level shifter wrapper.
//    - PDK Mapping: sky130_fd_sc_hd__lpflow_lsbuf_hl_1 (dual-rail standard cell).
//    - Pin Interface: A (1.80V input), VPWR (VDD_CORE), VMAX (1.80V), VGND, VNB, X.
// 3. cdc_handshake_synchronizer: 4-phase Request/Acknowledge (REQ/ACK) bus synchronizer.
//    - Solves multi-bit skew and metastability when passing arbitrary margin code jumps
//      (e.g., 8 -> 0 or 2 -> 7) across clk_core (75.0 MHz) and clk_ctrl (12.5 MHz).
//    - Guarantees the data bus is held completely stable before REQ is asserted and
//      throughout the destination domain sampling window.
// 4. cdc_gray_synchronizer: Generic parameterized binary-to-Gray synchronizer.
// ==============================================================================

`timescale 1ns / 1ps

// ------------------------------------------------------------------------------
// Low-to-High Level Shifter (e.g. 0.90V - 1.50V Core Rail up to 1.80V IO Rail)
// In physical design, this maps to sky130_fd_sc_hd__lpflow_lsbuf_lh_1.
// ------------------------------------------------------------------------------
(* keep_hierarchy = 1 *)
module level_shifter_lh #(
    parameter integer WIDTH = 1
)(
    input  wire [WIDTH-1:0] in_low,
    output wire [WIDTH-1:0] out_high
);
    // Behavioral delay representation for functional simulation
    assign #(0.12) out_high = in_low;
endmodule

// ------------------------------------------------------------------------------
// High-to-Low Level Shifter (e.g. 1.80V IO Rail down to 0.90V - 1.50V Core Rail)
// In physical design, this maps to sky130_fd_sc_hd__lpflow_lsbuf_hl_1.
// ------------------------------------------------------------------------------
(* keep_hierarchy = 1 *)
module level_shifter_hl #(
    parameter integer WIDTH = 1
)(
    input  wire [WIDTH-1:0] in_high,
    output wire [WIDTH-1:0] out_low
);
    // Behavioral delay representation for functional simulation
    assign #(0.10) out_low = in_high;
endmodule

// ------------------------------------------------------------------------------
// Coherent Request/Acknowledge (REQ/ACK) Bus Synchronizer
// ------------------------------------------------------------------------------
// Multi-bit measurement results (such as the CPM margin code) can jump by
// multiple steps in a single cycle (e.g. 8 -> 0 during voltage droop).
// A simple Gray-code synchronizer fails when multiple bits change simultaneously.
// This 4-phase REQ/ACK handshake protocol provides absolute data coherency:
// 1. Source domain registers data and asserts req.
// 2. Data remains 100% stable while req synchronizes into destination domain.
// 3. Destination registers the stable bus and asserts ack.
// 4. Source receives synchronized ack and deasserts req.
// 5. Destination deasserts ack, completing the 4-phase cycle.
// ------------------------------------------------------------------------------
module cdc_handshake_synchronizer #(
    parameter integer WIDTH = 4
)(
    // Source Clock Domain (Fast: clk_core = 75.0 MHz)
    input  wire             src_clk,
    input  wire             src_rst_n,
    input  wire [WIDTH-1:0] src_data,
    input  wire             src_valid,
    output reg              src_busy,

    // Destination Clock Domain (Slow: clk_ctrl = 12.5 MHz)
    input  wire             dest_clk,
    input  wire             dest_rst_n,
    output reg  [WIDTH-1:0] dest_data,
    output reg              dest_valid
);

    // --------------------------------------------------------------------------
    // Source Domain Logic
    // --------------------------------------------------------------------------
    reg [WIDTH-1:0] data_hold;
    reg             req_src;
    wire            ack_sync2;

    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            data_hold <= {WIDTH{1'b0}};
            req_src   <= 1'b0;
            src_busy  <= 1'b0;
        end else begin
            if (!req_src && !ack_sync2) begin
                // Idle: ready for new data
                if (src_valid) begin
                    data_hold <= src_data;
                    req_src   <= 1'b1;
                    src_busy  <= 1'b1;
                end else begin
                    src_busy  <= 1'b0;
                end
            end else if (req_src && ack_sync2) begin
                // Acknowledge received: drop request
                req_src <= 1'b0;
            end else if (!req_src && !ack_sync2) begin
                src_busy <= 1'b0;
            end
        end
    end

    // --------------------------------------------------------------------------
    // Request Synchronizer: clk_core -> clk_ctrl (2-Stage Synchronizer)
    // --------------------------------------------------------------------------
    (* keep = "true" *) reg req_sync1;
    (* keep = "true" *) reg req_sync2;

    always @(posedge dest_clk or negedge dest_rst_n) begin
        if (!dest_rst_n) begin
            req_sync1 <= 1'b0;
            req_sync2 <= 1'b0;
        end else begin
            req_sync1 <= req_src;
            req_sync2 <= req_sync1;
        end
    end

    // --------------------------------------------------------------------------
    // Destination Domain Logic
    // --------------------------------------------------------------------------
    reg ack_dest;
    reg req_sync2_d1;

    always @(posedge dest_clk or negedge dest_rst_n) begin
        if (!dest_rst_n) begin
            dest_data    <= {WIDTH{1'b0}};
            dest_valid   <= 1'b0;
            ack_dest     <= 1'b0;
            req_sync2_d1 <= 1'b0;
        end else begin
            req_sync2_d1 <= req_sync2;
            dest_valid   <= 1'b0;

            if (req_sync2 && !ack_dest) begin
                // Latch stable data from source domain
                dest_data  <= data_hold;
                dest_valid <= 1'b1;
                ack_dest   <= 1'b1;
            end else if (!req_sync2 && ack_dest) begin
                // Request dropped: drop acknowledge
                ack_dest   <= 1'b0;
            end
        end
    end

    // --------------------------------------------------------------------------
    // Acknowledge Synchronizer: clk_ctrl -> clk_core (2-Stage Synchronizer)
    // --------------------------------------------------------------------------
    (* keep = "true" *) reg ack_sync1;
    (* keep = "true" *) reg ack_sync2_reg;

    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            ack_sync1     <= 1'b0;
            ack_sync2_reg <= 1'b0;
        end else begin
            ack_sync1     <= ack_dest;
            ack_sync2_reg <= ack_sync1;
        end
    end

    assign ack_sync2 = ack_sync2_reg;

endmodule

// ------------------------------------------------------------------------------
// Generic Parameterized Gray-Code Bus Synchronizer
// ------------------------------------------------------------------------------
module cdc_gray_synchronizer #(
    parameter integer WIDTH = 4
)(
    input  wire             src_clk,
    input  wire             src_rst_n,
    input  wire [WIDTH-1:0] bin_in,
    input  wire             dest_clk,
    input  wire             dest_rst_n,
    output wire [WIDTH-1:0] bin_out
);

    // 1. Binary-to-Gray Conversion
    reg [WIDTH-1:0] gray_src;
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            gray_src <= {WIDTH{1'b0}};
        end else begin
            gray_src <= bin_in ^ (bin_in >> 1);
        end
    end

    // 2. 2-Stage Destination Synchronizer
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

    // 3. Fully Parameterized Gray-to-Binary Conversion
    reg [WIDTH-1:0] bin_calc;
    integer b;
    always @(*) begin
        bin_calc[WIDTH-1] = gray_sync2[WIDTH-1];
        for (b = WIDTH-2; b >= 0; b = b - 1) begin
            bin_calc[b] = bin_calc[b+1] ^ gray_sync2[b];
        end
    end

    assign bin_out = bin_calc;

endmodule

// ------------------------------------------------------------------------------
// Simple 2-Flop Bit Synchronizer
// ------------------------------------------------------------------------------
module cdc_synchronizer #(
    parameter integer WIDTH = 1
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
