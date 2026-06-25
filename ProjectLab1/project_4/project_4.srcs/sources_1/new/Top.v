`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/30/2025 05:07:41 PM
// Design Name: 
// Module Name: Top
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


module top(
    // System inputs
    input wire clck,          // System clock
    //input wire rst,          // Reset signal
    
    
    // Motor outputs
    output wire In1,           // Motor 1 control 1
    output wire In2,           // Motor 2 control 1
    output wire In3,           // Motor 1 control 2
    output wire In4,           // Motor 2 control 2
    output wire enA,           // Motor 1 enable
    output wire enB,           // Motor 2 enable
    
    // Status outputs (for monitoring)
    output wire [2:0] intersection_counter,  // Current intersection count
    output wire [1:0] motor1_control,       // Current motor 1 state
    output wire [1:0] motor2_control        // Current motor 2 state
);

    // Internal wires for module connections
    wire [1:0] motor1_control_w;  // State machine to motor control
    wire [1:0] motor2_control_w;  // State machine to motor control

  

endmodule

