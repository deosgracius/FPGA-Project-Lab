`timescale 1ns/1ps
`include "top.v"

module top_tb;
  // Testbench signals
  reg  clk;
  reg  left;
  reg  front;
  reg  right;
  reg  back;
  wire enA, enB;
  wire [1:0] MotorL, MotorR;

  // Instantiate the module under test (DUT)
  top_module dut (
    .clk   (clk),
    .left  (left),
    .front (front),
    .right (right),
    .back  (back),
    .enA   (enA),
    .enB   (enB),
    .MotorL(MotorL),
    .MotorR(MotorR)
  );

  // Generate a clock: toggles every 5 ns -> period of 10 ns
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Apply stimulus and record waveforms
  initial begin
    // Create VCD file
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);

    // Initial conditions
    left  = 0; front = 0; right = 0; back = 0;
    #20;

    // Toggle one sensor at a time
    left  = 1; front = 0; right = 0; back = 0; #40;
    left  = 0; front = 1; right = 0; back = 0; #40;
    left  = 0; front = 0; right = 1; back = 0; #40;
    left  = 0; front = 0; right = 0; back = 1; #40;

    // Multiple sensors active
    left  = 1; front = 1; right = 0; back = 0; #40;
    left  = 0; front = 1; right = 1; back = 0; #40;
    left  = 0; front = 0; right = 1; back = 1; #40;
    left  = 1; front = 0; right = 0; back = 1; #40;

    // All sensors active
    left  = 1; front = 1; right = 1; back = 1; #40;

    // End simulation
    $finish;
  end

endmodule

