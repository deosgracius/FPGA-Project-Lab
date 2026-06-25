`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2025 09:13:52 AM
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

module top_module(
    input clk,
    //input rst,
    input Lsensor,
    input Rsensor,
    output enA,
    output enB,
    output in1,
    output in2,
    output in3,
    output in4
);

    // Internal wires
    wire [1:0] sensor_out;       
    wire intersection;           
    wire [1:0] stateL, stateR;   
    wire mission_complete;       

    // Instantiate the Sensor Module
    sensor sensor_module (
        .Lsensor(Lsensor),
        .Rsensor(Rsensor),
        .sensor_out(sensor_out),
        .intersection(intersection)
    );

    // Instantiate the State Machine
    state_machine sm (
        .clk(clk),
        .rst(rst),
        .sensor_out(sensor_out),
        .intersection(intersection),
        .stateL(stateL),
        .stateR(stateR),
        .mission_complete(mission_complete)
    );

    // Instantiate the Motor Control Module
    motor_control mc (
        .stateL(stateL),
        .stateR(stateR),
        .enA(enA),
        .enB(enB),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .in4(in4)
    );

endmodule



