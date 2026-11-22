// ==============================================================================
// Module: avs_controller.v
// Project: Closed-Loop AVS Power Management Macro on Sky130
// Description: Closed-Loop Adaptive Voltage Scaling 6-State FSM Controller.
//              Features:
//              - 6-State FSM: ST_RESET, ST_WAIT_SETTLE, ST_SAMPLE,
//                ST_EVALUATE, ST_UPDATE_STEP, ST_EMERGENCY.
//              - Rate-limited stepping (max +/- 1 LSB per update interval)
//              - Settling-time timer (waits for analog LDO transient before sampling)
//              - Configurable hysteresis window to prevent limit-cycle hunting
//              - Programmable floor (0.90V) and ceiling (1.50V) safety clamping
//              - Synchronous emergency override: Evaluated on every rising edge of
//                clk_ctrl (latency <= 1 controller clock cycle = 80 ns at 12.5 MHz)
// ==============================================================================

`timescale 1ns / 1ps

module avs_controller #(
    parameter integer CODE_WIDTH       = 5,
    parameter integer MARGIN_WIDTH     = 4,
    parameter integer SETTLE_CYCLES    = 16,
    parameter [CODE_WIDTH-1:0] V_MIN   = 5'd0,   // 0.90V
    parameter [CODE_WIDTH-1:0] V_MAX   = 5'd31,  // 1.50V (Safe Sign-Off Ceiling)
    parameter [CODE_WIDTH-1:0] V_INIT  = 5'd31   // Boot at maximum safe voltage
)(
    input  wire                    clk_ctrl,        // 10 - 25 MHz controller clock
    input  wire                    rst_n,           // Asynchronous active-low reset
    input  wire                    avs_enable,      // 1 = Enable closed loop, 0 = Manual
    input  wire [CODE_WIDTH-1:0]   manual_code,     // Voltage code in manual mode
    input  wire [MARGIN_WIDTH-1:0] target_margin,   // Target guard-band (default = 2 taps)
    input  wire [MARGIN_WIDTH-1:0] margin_code_in,  // Synchronized CPM margin code
    output reg  [CODE_WIDTH-1:0]   v_code,          // Output code to 5-bit Reference DAC
    output reg                     timing_hazard,   // Emergency hazard alarm
    output reg                     settled,         // Asserted when within target deadband
    output reg  [2:0]              fsm_state        // Exposed FSM state for observability
);

    // FSM State Encoding
    localparam [2:0]
        ST_RESET       = 3'd0,
        ST_WAIT_SETTLE = 3'd1,
        ST_SAMPLE      = 3'd2,
        ST_EVALUATE    = 3'd3,
        ST_UPDATE_STEP = 3'd4,
        ST_EMERGENCY   = 3'd5;

    reg [7:0] settle_counter;
    reg [MARGIN_WIDTH-1:0] sampled_margin;

    // --------------------------------------------------------------------------
    // Main Control FSM Sequential Process
    // --------------------------------------------------------------------------
    always @(posedge clk_ctrl or negedge rst_n) begin
        if (!rst_n) begin
            fsm_state      <= ST_RESET;
            v_code         <= V_INIT;
            timing_hazard  <= 1'b0;
            settled        <= 1'b0;
            settle_counter <= 8'd0;
            sampled_margin <= {MARGIN_WIDTH{1'b0}};
        end else if (!avs_enable) begin
            // Manual Override Mode: directly pass manual code bounded by safety limits
            fsm_state      <= ST_RESET;
            settled        <= 1'b1;
            timing_hazard  <= 1'b0;
            if (manual_code > V_MAX)
                v_code <= V_MAX;
            else if (manual_code < V_MIN)
                v_code <= V_MIN;
            else
                v_code <= manual_code;
        end else if (margin_code_in == {MARGIN_WIDTH{1'b0}} && fsm_state != ST_RESET) begin
            // IMMEDIATE CRITICAL INTERRUPT: Timing margin is ZERO!
            // Instantly override state machine, restore maximum voltage, assert alarm
            fsm_state      <= ST_EMERGENCY;
            v_code         <= V_MAX;
            timing_hazard  <= 1'b1;
            settled        <= 1'b0;
            settle_counter <= 8'd0;
        end else begin
            case (fsm_state)
                ST_RESET: begin
                    v_code         <= V_INIT;
                    timing_hazard  <= 1'b0;
                    settled        <= 1'b0;
                    settle_counter <= 8'd0;
                    fsm_state      <= ST_WAIT_SETTLE;
                end

                ST_WAIT_SETTLE: begin
                    // Wait for LDO analog output to settle after step adjustment
                    if (settle_counter >= SETTLE_CYCLES) begin
                        settle_counter <= 8'd0;
                        fsm_state      <= ST_SAMPLE;
                    end else begin
                        settle_counter <= settle_counter + 8'd1;
                    end
                end

                ST_SAMPLE: begin
                    // Capture current synchronized CPM timing margin
                    sampled_margin <= margin_code_in;
                    fsm_state      <= ST_EVALUATE;
                end

                ST_EVALUATE: begin
                    // Check margin against target window with hysteresis
                    // Target Window: [target_margin, target_margin + 1]
                    if (sampled_margin < target_margin) begin
                        // Insufficient timing margin: Must step UP voltage (+1 LSB code)
                        settled <= 1'b0;
                        if (v_code < V_MAX) begin
                            v_code <= v_code + 1'b1;
                        end
                        fsm_state <= ST_UPDATE_STEP;
                    end else if (sampled_margin > (target_margin + 4'd1)) begin
                        // Excess timing margin (over-designed): Step DOWN voltage (-1 LSB code)
                        settled <= 1'b0;
                        if (v_code > V_MIN) begin
                            v_code <= v_code - 1'b1;
                        end
                        fsm_state <= ST_UPDATE_STEP;
                    end else begin
                        // Within hysteresis deadband: Locked and optimal!
                        settled   <= 1'b1;
                        fsm_state <= ST_WAIT_SETTLE;
                    end
                end

                ST_UPDATE_STEP: begin
                    // Step commanded, now return to settling wait
                    settle_counter <= 8'd0;
                    fsm_state      <= ST_WAIT_SETTLE;
                end

                ST_EMERGENCY: begin
                    // Held in emergency until margin recovered AND analog rail has settled
                    v_code  <= V_MAX;
                    settled <= 1'b0;
                    if (margin_code_in > {MARGIN_WIDTH{1'b0}}) begin
                        if (settle_counter >= (SETTLE_CYCLES * 2)) begin
                            settle_counter <= 8'd0;
                            timing_hazard  <= 1'b0; // Clear hazard once safely stabilized
                            fsm_state      <= ST_WAIT_SETTLE;
                        end else begin
                            settle_counter <= settle_counter + 8'd1;
                        end
                    end else begin
                        // Keep asserting hazard as long as margin is 0
                        timing_hazard  <= 1'b1;
                        settle_counter <= 8'd0;
                    end
                end

                default: fsm_state <= ST_RESET;
            endcase
        end
    end

endmodule
