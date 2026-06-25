`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2025 09:06:36 AM
// Design Name: 
// Module Name: Statem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module motor_control(
    input [1:0] stateL,  // Left motor: 00 = Stop, 01 = Forward, 10 = Backward
    input [1:0] stateR,  // Right motor: 00 = Stop, 01 = Forward, 10 = Backward
    output enA,          // Enable Left Motor (Always ON)
    output enB,          // Enable Right Motor (Always ON)
    output in1,          // Left Motor Forward
    output in2,          // Left Motor Backward
    output in3,          // Right Motor Forward
    output in4           // Right Motor Backward
);

    // Enable both motors
    assign enA = 1'b1;
    assign enB = 1'b1;

    // Boolean equations for motor control logic
    assign in1 = (stateL == 2'b01);  // Left motor forward
    assign in2 = (stateL == 2'b10);  // Left motor backward
    assign in3 = (stateR == 2'b01);  // Right motor forward
    assign in4 = (stateR == 2'b10);  // Right motor backward

endmodule

