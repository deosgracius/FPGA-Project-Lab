`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2025 04:12:28 AM
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


module motor_control(
    input [1:0] stateL,  // Left motor: 00 = Stop, 01 = Forward, 10 = Reverse
    input [1:0] stateR,  // Right motor: 00 = Stop, 01 = Forward, 10 = Reverse
    output enA,          
    output enB,          
    output in1,          
    output in2,          
    output in3,          
    output in4           
);

    // Enable both motors
    assign enA = 1'b1;
    assign enB = 1'b1;
    
    // Motor control equations
    assign in1 = (stateL == 2'b01);  // Left motor forward
    assign in2 = (stateL == 2'b10);  // Left motor reverse
    assign in3 = (stateR == 2'b10);  // Right motor reverse 
    assign in4 = (stateR == 2'b01);  // Right motor forward
endmodule
