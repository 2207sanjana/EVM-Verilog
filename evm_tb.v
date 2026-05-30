/*
 * EVM Testbench
 * Author : Sanjana Banala
 * Description: Simulates voting sequences and verifies counter logic.
 */

`timescale 1ns / 1ps

module evm_tb;

reg clk, rst;
reg vote_A, vote_B, vote_C, vote_D;
reg show_result, next_display;

wire [6:0] seg;
wire [3:0] an;
wire led_A, led_B, led_C, led_D, locked_led;

// Instantiate DUT
evm_top uut (
    .clk(clk), .rst(rst),
    .vote_A(vote_A), .vote_B(vote_B),
    .vote_C(vote_C), .vote_D(vote_D),
    .show_result(show_result),
    .next_display(next_display),
    .seg(seg), .an(an),
    .led_A(led_A), .led_B(led_B),
    .led_C(led_C), .led_D(led_D),
    .locked_led(locked_led)
);

// 100 MHz clock
initial clk = 0;
always #5 clk = ~clk;

task cast_vote;
    input [3:0] candidate; // 0=A 1=B 2=C 3=D
    begin
        case (candidate)
            0: begin vote_A=1; #20; vote_A=0; end
            1: begin vote_B=1; #20; vote_B=0; end
            2: begin vote_C=1; #20; vote_C=0; end
            3: begin vote_D=1; #20; vote_D=0; end
        endcase
        #50;
    end
endtask

task reset_machine;
    begin
        rst = 1; #30; rst = 0; #20;
    end
endtask

initial begin
    $display("=== EVM Simulation Start ===");
    {vote_A,vote_B,vote_C,vote_D,show_result,next_display} = 6'b0;
    reset_machine;

    // Voter 1 votes A
    $display("Voter 1 votes A");
    cast_vote(0);
    $display("count_A=%0d locked=%b", uut.count_A, uut.voted);

    // Voter 1 tries to vote again (should be locked)
    $display("Voter 1 tries again (should be locked)");
    cast_vote(1);
    $display("count_B=%0d locked_led=%b", uut.count_B, locked_led);

    // New voter session — reset
    reset_machine;

    // Voter 2 votes B
    $display("Voter 2 votes B");
    cast_vote(1);

    // New voter session
    reset_machine;

    // Voter 3 votes A
    $display("Voter 3 votes A");
    cast_vote(0);

    // New voter session
    reset_machine;

    // Voter 4 votes C
    $display("Voter 4 votes C");
    cast_vote(2);

    // Show results
    show_result = 1; #20; show_result = 0;
    $display("=== Final Results ===");
    $display("A: %0d | B: %0d | C: %0d | D: %0d",
        uut.count_A, uut.count_B, uut.count_C, uut.count_D);
    $display("=== Simulation Complete ===");
    $finish;
end

endmodule
