// ==============================================================================
// Module: pipelined_mac_load.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Pipelined 16-bit Multiplier-Accumulator (MAC) Digital Load.
//              Contains a built-in pseudo-random LFSR activity generator
//              to induce dynamic power steps and realistic current transients
//              on the regulated VDD_CORE rail.
// ==============================================================================

`timescale 1ns / 1ps

module pipelined_mac_load (
    input  wire        clk_core,        // Core clock (50 - 100 MHz)
    input  wire        rst_n,           // Asynchronous active-low reset
    input  wire        load_enable,     // Datapath compute enable
    input  wire        stress_mode,     // 1 = High-activity LFSR burst, 0 = Normal
    input  wire [15:0] operand_a_in,    // Deterministic operand A
    input  wire [15:0] operand_b_in,    // Deterministic operand B
    output reg  [31:0] mac_result_out,  // 32-bit accumulated result
    output reg         activity_pulse   // Toggling activity monitor pin
);

    // --------------------------------------------------------------------------
    // Pseudo-Random LFSR Activity Generator (16-bit Galois LFSR)
    // Polynomial: x^16 + x^14 + x^13 + x^11 + 1
    // --------------------------------------------------------------------------
    reg [15:0] lfsr_reg;
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= 16'hACE1;
        end else if (stress_mode) begin
            lfsr_reg <= {lfsr_reg[14:0], 1'b0} ^ (lfsr_reg[15] ? 16'h002D : 16'h0000);
        end
    end

    // Mux between external deterministic inputs and high-activity stress LFSR
    wire [15:0] op_a = stress_mode ? lfsr_reg : operand_a_in;
    wire [15:0] op_b = stress_mode ? ~lfsr_reg : operand_b_in;

    // --------------------------------------------------------------------------
    // Pipeline Stage 1: Operand Input Registers
    // --------------------------------------------------------------------------
    reg [15:0] reg_a_s1;
    reg [15:0] reg_b_s1;
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            reg_a_s1 <= 16'd0;
            reg_b_s1 <= 16'd0;
        end else if (load_enable) begin
            reg_a_s1 <= op_a;
            reg_b_s1 <= op_b;
        end
    end

    // --------------------------------------------------------------------------
    // Pipeline Stage 2: 16-Bit Multiplier Stage
    // --------------------------------------------------------------------------
    wire [31:0] mult_comb = reg_a_s1 * reg_b_s1;
    reg  [31:0] mult_reg_s2;
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            mult_reg_s2 <= 32'd0;
        end else if (load_enable) begin
            mult_reg_s2 <= mult_comb;
        end
    end

    // --------------------------------------------------------------------------
    // Pipeline Stage 3: 32-Bit Accumulation Stage
    // --------------------------------------------------------------------------
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            mac_result_out <= 32'd0;
            activity_pulse <= 1'b0;
        end else if (load_enable) begin
            mac_result_out <= mac_result_out + mult_reg_s2;
            activity_pulse <= ^mac_result_out; // Dynamic parity toggle
        end
    end

endmodule
