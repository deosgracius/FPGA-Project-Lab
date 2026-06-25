`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2025 10:39:18 PM
// Design Name: 
// Module Name: top
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

    input clk,          // 100 MHz clock

    //input rst_n,        // Active-low reset (physical button)

    input prox1,        // Proximity sensor input (active low)

    input prox2, // Limit switch input (active high)

    output pwm_out,     // Servo PWM signal

    output mosfet       // Motor control signal

);

 

// Internal reset signal (convert to active-high)


 

// Servo controller instance

servo_controller servo_inst(

    .clk(clk),

    .prox1(prox1),

    .pwm_out(pwm_out),

    .servo_closed(servo_closed)

);

 

// Motor controller instance

motor_control motor_inst(

    .clk(clk),

    .start_lift(servo_closed),

    .prox2(prox2),

    .mosfet(mosfet)

);

 

endmodule
