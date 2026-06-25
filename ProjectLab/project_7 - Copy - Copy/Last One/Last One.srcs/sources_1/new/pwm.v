`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2025 01:49:58 AM
// Design Name: 
// Module Name: pwm
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


module pwm_generator(
    input clk,
    input reset,
    input [7:0] duty_cycle,  // 8-bit duty cycle for 256 steps of control
    output reg pwm_out
);

    reg [7:0] counter = 8'd0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 8'd0;
            pwm_out <= 1'b0;
        end else begin
            counter <= counter + 1'b1;
            if (counter < duty_cycle)
                pwm_out <= 1'b1;  // High for the duration of duty cycle
            else
                pwm_out <= 1'b0;  // Low for the rest of the cycle
        end
    end
endmodule