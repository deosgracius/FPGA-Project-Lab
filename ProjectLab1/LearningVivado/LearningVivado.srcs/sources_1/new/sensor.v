`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2025 06:28:27 AM
// Design Name: 
// Module Name: sensor
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




module sensor(
    input Lsensor,      
    input Rsensor,      
    output [1:0] sensor_out, 
    output intersection  
);

    // Active-low sensors: 0 = detects metal, 1 = no metal
    assign sensor_out[1] = ~Lsensor;  // Inverted
    assign sensor_out[0] = ~Rsensor;  // Inverted

    // Intersection occurs when both sensors detect metal (LOW)
    assign intersection = ~(Lsensor | Rsensor);

endmodule






