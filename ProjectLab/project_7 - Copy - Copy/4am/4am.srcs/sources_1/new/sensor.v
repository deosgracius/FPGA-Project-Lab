`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2025 04:12:07 AM
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
    input Msensor1,     // Front left sensor
    input Msensor2,     // Front right sensor
    input Lsensor,      // Left side sensor
    input Rsensor,      // Back middle sensor
    output [3:0] sensor_out 
);

    // Active-low sensors: invert so that 1 = metal detected
    assign sensor_out[3] = ~Msensor1; // Front left
    assign sensor_out[2] = ~Msensor2; // Front right
    assign sensor_out[1] = ~Lsensor;  // Left side
    assign sensor_out[0] = ~Rsensor;  // Back middle

endmodule
