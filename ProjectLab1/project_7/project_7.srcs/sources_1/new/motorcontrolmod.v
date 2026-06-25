`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2025 09:20:18 AM
// Design Name: 
// Module Name: motorcontrolmod
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
    
    //Left Motor Backward
    // (stateL == 2'b10);  // Left motor forward , 
    // (stateL == 2'b01);  // Left motor backward
    
    // Right Motor 
    //stateR == 2'b01);  // Right motor forward
    //(stateR == 2'b10);  // Right motor backward
    
    
    // Boolean equations for motor control logic                     Left Motor
    assign in1 = (stateL == 2'b01);  // Left motor forward           (stateL == 2'b10);  // Left motor forward ,                     
    assign in2 = (stateL == 2'b10);  // Left motor backward          (stateL == 2'b01);  // Left motor backward
    
    //                                                               Right Motor  
    assign in3 = (stateR == 2'b10);  // Right motor forward          (stateR == 2'b01);  // Right motor forward
    assign in4 = (stateR == 2'b01);  // Right motor backward         (stateR == 2'b10);  // Right motor backward

endmodule


