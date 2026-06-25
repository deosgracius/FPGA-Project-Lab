`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2025 05:35:36 PM
// Design Name: 
// Module Name: SensorBehavior
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


// Sensor Behavior Module
module Sensor_Behavior(
    input wire sensor_west,
    input wire sensor_east,
    output wire sensor_or
);
    // Truth table: OR operation
    assign sensor_or = sensor_west | sensor_east;
endmodule

