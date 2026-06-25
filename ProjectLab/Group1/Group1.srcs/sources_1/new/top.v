`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/05/2025 03:23:31 AM
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


module top (
    input clk,
    input S0, S1, S2, // Sensor inputs
    output ENA, ENB, IN4, IN3, IN2, IN1 // Motor control outputs
);

    wire [2:0] sensor_output;
    wire [2:0] motor_control;
    wire reverse_flag;

    sensor_module sensor (
        .S0(S0),
        .S1(S1),
        .S2(S2),
        .reverse(reverse_flag),
        .L2(sensor_output[2]),
        .L1(sensor_output[1]),
        .L0(sensor_output[0])
    );

    autonomous_robot control (
        .clk(clk),
        .sensor(sensor_output),
        .motor(motor_control),
        .reverse(reverse_flag),
        .state() // Debugging output, not used in top
    );

    motor_module motor (
        .M(motor_control),
        .ENA(ENA),
        .ENB(ENB),
        .IN4(IN4),
        .IN3(IN3),
        .IN2(IN2),
        .IN1(IN1)
    );

endmodule