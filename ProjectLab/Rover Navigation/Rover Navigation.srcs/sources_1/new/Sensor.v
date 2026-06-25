`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2025 08:30:14 PM
// Design Name: 
// Module Name: Sensor
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
 

module sensor_module(

    input sensor_left,     

    input sensor_right,    

    input sensor_T,         // T-intersection sensor (active low)

    output reg [2:0] sensor_status // [left, right, T] (active high)

);

    always @(*) begin

        sensor_status[2] = ~sensor_left;    // Convert to active high

        sensor_status[1] = ~sensor_right;

        sensor_status[0] = ~sensor_T;

    end

endmodule