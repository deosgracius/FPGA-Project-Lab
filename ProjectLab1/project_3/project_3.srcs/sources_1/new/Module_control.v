`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2025 06:43:06 PM
// Design Name: 
// Module Name: Module_control
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

// Motor Control Module
module Motor_control(
    input wire enable_a, // Enable A for Motor 1
    input wire enable_b, // Enable B for Motor 2
    input wire in1,      // Input 1 for Motor 1
    input wire in2,      // Input 2 for Motor 1
    input wire in3,      // Input 3 for Motor 2
    input wire in4,      // Input 4 for Motor 2
    output wire m1,      // Motor 1 output (direction controlled by in1, in2)
    output wire m2       // Motor 2 output (direction controlled by in3, in4)
);
    // Motors are enabled when enable_a and enable_b are 1
    assign m1 = enable_a & (in1 | in2);
    assign m2 = enable_b & (in3 | in4);
endmodule
