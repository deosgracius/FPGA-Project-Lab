`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2025 10:03:56 PM
// Design Name: 
// Module Name: DC_motor
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


// DC Motor Controller with Instant Stop

module dc_motor_controller(

    input clk,

    input rst,

    input enable,

    input emergency_stop,

    output reg pwm_out

);

 

parameter PWM_PERIOD = 100_000; // 1kHz

reg [31:0] pwm_counter;

 

always @(posedge clk or posedge rst) begin

    if (rst || emergency_stop) begin

        pwm_counter <= 0;

        pwm_out <= 0;

    end else if (enable) begin

        pwm_counter <= (pwm_counter < PWM_PERIOD) ? pwm_counter + 1 : 0;

        pwm_out <= (pwm_counter < PWM_PERIOD*9/10) ? 1'b1 : 1'b0; // 90% duty

    end

end

endmodule
