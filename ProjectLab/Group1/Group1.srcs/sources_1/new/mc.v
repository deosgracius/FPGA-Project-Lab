`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/05/2025 03:23:01 AM
// Design Name: 
// Module Name: mc
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


module motor_module(
    input  [2:0] M,   // Command bits (M2, M1, M0)
    output ENA,  // Enables forward motion for both motors
    output ENB,  // Enables reverse motion for both motors
    output IN4,  // Right motor forward input
    output IN3,  // Right motor reverse input
    output IN2,  // Left motor forward input
    output IN1   // Left motor reverse input
);

    assign ENA = ~M[1] & ~M[0] | ~M[2] & M[1]; // Forward enable
    assign ENB = M[0] | ~M[2] & ~M[1]; // Reverse enable
    assign IN4 = ~M[2] & ~M[1]; // Right motor forward
    assign IN3 = M[1] | M[2]; // Right motor reverse
    assign IN2 = ~M[2] & ~M[0]; // Left motor forward
    assign IN1 = M[0] | M[2]; // Left motor reverse
endmodule