`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2025 11:31:26 AM
// Design Name: 
// Module Name: edge_detector
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


// Edge detector for button press

module edge_detector(

    input clk,

    input signal_in,

    output pulse_out

);

    reg signal_delay;

    always @(posedge clk) signal_delay <= signal_in;

    assign pulse_out = signal_in & ~signal_delay;

endmodule

