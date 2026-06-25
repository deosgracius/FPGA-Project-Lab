`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/05/2025 03:22:46 AM
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


module sensor_module(
    input  S0,      // Front sensor
    input  S1,      // Right sensor
    input  S2,      // Left sensor
    input  reverse, // 0 = forward, 1 = reverse
    output reg L2,  // Processed sensor output
    output reg L1,  // Processed sensor output
    output reg L0   // Processed sensor output
);

    always @(*) begin
        if (reverse == 1'b0) begin
            L2 = (S1 & S0) | (S2 & S0);
            L1 = ~S1 & ~S0;
            L0 = ~S2 & ~S0;
        end else begin
            L2 = (S1 & S0) | (S2 & S0);
            L1 = ~S2 & ~S0; // Swapped for reverse
            L0 = ~S1 & ~S0; // Swapped for reverse
        end
    end
endmodule