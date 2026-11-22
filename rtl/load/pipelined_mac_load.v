// ==============================================================================
// Module: pipelined_mac_load.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Pipelined 16-bit Multiplier-Accumulator (MAC) Digital Load
//              with integrated Dynamic Workload Activity Sentinel (Phase E).
//              Monitors arithmetic switching activity and carry generation to
//              dynamically select between Multiplier Array and Carry-Propagate
//              replica paths, resolving critical-path masking during compute bursts.
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
    output reg         activity_pulse,  // Toggling activity monitor pin
    output reg         path_select,     // Dynamic replica select: 0 = Multiplier, 1 = Carry
    output reg         workload_burst   // Asserted during compute bursts / carry propagation
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
    // Pipeline Stage 3: Two-Stage 32-Bit Accumulation
    // Splits the 32-bit ripple carry chain into 16-bit half-words to eliminate
    // long carry delay chains and guarantee timing closure.
    // --------------------------------------------------------------------------
    reg [15:0] acc_low_reg;
    reg        acc_carry_s3a;
    reg [15:0] mult_high_s3a;
    wire [16:0] acc_low_comb = acc_low_reg + mult_reg_s2[15:0];

    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            acc_low_reg   <= 16'd0;
            acc_carry_s3a <= 1'b0;
            mult_high_s3a <= 16'd0;
        end else if (load_enable) begin
            acc_low_reg   <= acc_low_comb[15:0];
            acc_carry_s3a <= acc_low_comb[16];
            mult_high_s3a <= mult_reg_s2[31:16];
        end
    end

    reg [15:0] acc_high_reg;
    wire [16:0] acc_high_comb = acc_high_reg + mult_high_s3a + acc_carry_s3a;

    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            acc_high_reg   <= 16'd0;
            mac_result_out <= 32'd0;
            activity_pulse <= 1'b0;
        end else if (load_enable) begin
            acc_high_reg   <= acc_high_comb[15:0];
            mac_result_out <= {acc_high_comb[15:0], acc_low_reg};
            activity_pulse <= ^mac_result_out;
        end
    end

    // --------------------------------------------------------------------------
    // Workload Activity Sentinel (Phase E Implementation)
    // Tracks dynamic operand Hamming toggles and carry generation across cycles.
    // When compute bursts or multi-bit carry chains occur, selects the Accumulator
    // Carry-Propagate replica to prevent critical-path masking.
    // --------------------------------------------------------------------------
    wire [15:0] a_diff = op_a ^ reg_a_s1;
    wire [15:0] b_diff = op_b ^ reg_b_s1;
    wire [4:0]  a_toggles = a_diff[0] + a_diff[1] + a_diff[2] + a_diff[3] +
                            a_diff[4] + a_diff[5] + a_diff[6] + a_diff[7] +
                            a_diff[8] + a_diff[9] + a_diff[10] + a_diff[11] +
                            a_diff[12] + a_diff[13] + a_diff[14] + a_diff[15];
    wire [4:0]  b_toggles = b_diff[0] + b_diff[1] + b_diff[2] + b_diff[3] +
                            b_diff[4] + b_diff[5] + b_diff[6] + b_diff[7] +
                            b_diff[8] + b_diff[9] + b_diff[10] + b_diff[11] +
                            b_diff[12] + b_diff[13] + b_diff[14] + b_diff[15];
    wire [5:0]  total_toggles = a_toggles + b_toggles;

    reg [2:0] burst_decay_cnt;
    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            burst_decay_cnt <= 3'd0;
            path_select     <= 1'b0;
            workload_burst  <= 1'b0;
        end else if (load_enable) begin
            if (stress_mode || acc_carry_s3a || (total_toggles >= 6'd8)) begin
                burst_decay_cnt <= 3'd7; // Saturate 7-cycle decay timer
                path_select     <= 1'b1; // Direct monitor to Carry-Propagate Replica
                workload_burst  <= 1'b1;
            end else if (burst_decay_cnt > 3'd0) begin
                burst_decay_cnt <= burst_decay_cnt - 3'd1;
                path_select     <= 1'b1; // Maintain carry replica during active window
                workload_burst  <= 1'b1;
            end else begin
                path_select     <= 1'b0; // Revert to Multiplier Array Replica
                workload_burst  <= 1'b0;
            end
        end
    end

endmodule
