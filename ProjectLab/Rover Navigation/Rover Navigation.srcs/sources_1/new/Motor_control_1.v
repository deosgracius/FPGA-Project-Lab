`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2025 08:32:29 PM
// Design Name: 
// Module Name: Motor_control_1
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
    input [1:0] stateL,     // Left motor: 00=Stop, 01=Forward, 10=Reverse
    input [1:0] stateR,     // Right motor
    output enA, enB,        // Motor enables
    output in1, in2, in3, in4

);
    // Enable both motors
    assign enA = 1'b1;
    assign enB = 1'b1;
    assign in1 = (stateL == 2'b01);  // Left forward
    assign in2 = (stateL == 2'b10);  // Left reverse
    assign in3 = (stateR == 2'b10);  // Right reverse
    assign in4 = (stateR == 2'b01);  // Right forward
endmodule


