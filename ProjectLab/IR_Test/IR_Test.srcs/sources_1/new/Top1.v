`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2025 08:14:43 PM
// Design Name: 
// Module Name: Top1
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


module topmodule (
    input clk,          // 100 MHz clock from Basys 3
    input ir_input,     // IR sensor input
    output [15:0] led   // 16 individual LEDs on Basys 3
);

    // Wire to connect the frequency output from the IR receiver
    wire [1:0] freq_out;

    // Instantiate the IR receiver module
    ir_receiver ir_rec_instance (
        .clk(clk),
        .ir_input(ir_input),
        .freq_out(freq_out)
    );

    // Assign LEDs based on the detected frequency
    assign led[0] = (freq_out == 2'b00);  // LED[0] on for 1 kHz
    assign led[1] = (freq_out == 2'b01);  // LED[1] on for 2 kHz
    assign led[2] = (freq_out == 2'b10);  // LED[2] on for 3 kHz
    assign led[3] = (freq_out == 2'b11);  // LED[3] on for invalid
    assign led[15:4] = 12'b0;             // Keep remaining LEDs off

endmodule
