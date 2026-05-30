/*
 * Electronic Voting Machine (EVM) — Verilog HDL
 * Author : Sanjana Banala
 * Tool   : Xilinx Vivado
 * Board  : Basys3 / Nexys4 FPGA
 *
 * Description:
 *   A hardware Electronic Voting Machine supporting 4 candidates.
 *   Voters press a button to cast a vote. The system prevents
 *   duplicate voting per session. Results are displayed on a
 *   7-segment display. An admin RESULT button shows final counts.
 *
 * Inputs:
 *   clk         — system clock
 *   rst         — active-high reset
 *   vote_A/B/C/D — vote buttons for candidates A, B, C, D
 *   show_result  — display result mode
 *   next_display — cycle through candidates on 7-seg
 *
 * Outputs:
 *   seg[6:0]    — 7-segment display segments
 *   an[3:0]     — 7-segment anode select
 *   led_A/B/C/D — vote confirmation LEDs
 *   locked_led  — lit when vote already cast this session
 */

module evm_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        vote_A,
    input  wire        vote_B,
    input  wire        vote_C,
    input  wire        vote_D,
    input  wire        show_result,
    input  wire        next_display,
    output reg  [6:0]  seg,
    output reg  [3:0]  an,
    output reg         led_A,
    output reg         led_B,
    output reg         led_C,
    output reg         led_D,
    output reg         locked_led
);

// ── Vote Counters ──────────────────────────────────────────────
reg [7:0] count_A;
reg [7:0] count_B;
reg [7:0] count_C;
reg [7:0] count_D;

// ── Vote Lock (prevents double voting per session) ─────────────
reg voted;

// ── Display State ──────────────────────────────────────────────
reg [1:0] display_sel;  // 0=A, 1=B, 2=C, 3=D

// ── Button Edge Detection ──────────────────────────────────────
reg vA_prev, vB_prev, vC_prev, vD_prev;
reg res_prev, nxt_prev;

wire vA_edge  = vote_A       & ~vA_prev;
wire vB_edge  = vote_B       & ~vB_prev;
wire vC_edge  = vote_C       & ~vC_prev;
wire vD_edge  = vote_D       & ~vD_prev;
wire res_edge = show_result  & ~res_prev;
wire nxt_edge = next_display & ~nxt_prev;

// ── Voting Logic ───────────────────────────────────────────────
always @(posedge clk or posedge rst) begin
    if (rst) begin
        count_A    <= 8'd0;
        count_B    <= 8'd0;
        count_C    <= 8'd0;
        count_D    <= 8'd0;
        voted      <= 1'b0;
        led_A      <= 1'b0;
        led_B      <= 1'b0;
        led_C      <= 1'b0;
        led_D      <= 1'b0;
        locked_led <= 1'b0;
        vA_prev    <= 1'b0;
        vB_prev    <= 1'b0;
        vC_prev    <= 1'b0;
        vD_prev    <= 1'b0;
    end else begin
        // Update previous button states
        vA_prev <= vote_A;
        vB_prev <= vote_B;
        vC_prev <= vote_C;
        vD_prev <= vote_D;

        // Clear LEDs each cycle
        led_A <= 1'b0; led_B <= 1'b0;
        led_C <= 1'b0; led_D <= 1'b0;
        locked_led <= 1'b0;

        if (!voted) begin
            if (vA_edge) begin
                count_A <= count_A + 1;
                voted   <= 1'b1;
                led_A   <= 1'b1;
            end else if (vB_edge) begin
                count_B <= count_B + 1;
                voted   <= 1'b1;
                led_B   <= 1'b1;
            end else if (vC_edge) begin
                count_C <= count_C + 1;
                voted   <= 1'b1;
                led_C   <= 1'b1;
            end else if (vD_edge) begin
                count_D <= count_D + 1;
                voted   <= 1'b1;
                led_D   <= 1'b1;
            end
        end else begin
            // Already voted — show lock LED
            locked_led <= 1'b1;
        end
    end
end

// ── Display Selector ───────────────────────────────────────────
always @(posedge clk or posedge rst) begin
    if (rst) begin
        display_sel <= 2'd0;
        res_prev    <= 1'b0;
        nxt_prev    <= 1'b0;
    end else begin
        res_prev <= show_result;
        nxt_prev <= next_display;
        if (res_edge) display_sel <= 2'd0;  // reset to A on result press
        if (nxt_edge) display_sel <= display_sel + 1; // cycle A→B→C→D
    end
end

// ── 7-Segment Display ──────────────────────────────────────────
// Displays count of selected candidate as 2-digit decimal
reg [7:0] display_val;
always @(*) begin
    case (display_sel)
        2'd0: display_val = count_A;
        2'd1: display_val = count_B;
        2'd2: display_val = count_C;
        2'd3: display_val = count_D;
    endcase
end

// BCD conversion (units and tens)
wire [3:0] units = display_val % 10;
wire [3:0] tens  = (display_val / 10) % 10;

// 7-segment encoding: segments = {g,f,e,d,c,b,a} active-low
function [6:0] bcd_to_seg;
    input [3:0] bcd;
    case (bcd)
        4'd0: bcd_to_seg = 7'b1000000;
        4'd1: bcd_to_seg = 7'b1111001;
        4'd2: bcd_to_seg = 7'b0100100;
        4'd3: bcd_to_seg = 7'b0110000;
        4'd4: bcd_to_seg = 7'b0011001;
        4'd5: bcd_to_seg = 7'b0010010;
        4'd6: bcd_to_seg = 7'b0000010;
        4'd7: bcd_to_seg = 7'b1111000;
        4'd8: bcd_to_seg = 7'b0000000;
        4'd9: bcd_to_seg = 7'b0010000;
        default: bcd_to_seg = 7'b1111111;
    endcase
endfunction

// Clock divider for multiplexed display (~1kHz refresh)
reg [16:0] clk_div;
always @(posedge clk) clk_div <= clk_div + 1;
wire disp_clk = clk_div[16];

reg disp_sel;
always @(posedge disp_clk or posedge rst) begin
    if (rst) disp_sel <= 0;
    else     disp_sel <= ~disp_sel;
end

always @(*) begin
    if (disp_sel == 0) begin
        an  = 4'b1110;           // rightmost digit — units
        seg = bcd_to_seg(units);
    end else begin
        an  = 4'b1101;           // second digit — tens
        seg = bcd_to_seg(tens);
    end
end

endmodule
