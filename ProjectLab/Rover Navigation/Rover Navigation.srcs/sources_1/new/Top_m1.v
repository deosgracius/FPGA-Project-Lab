`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/07/2025 09:31:48 PM
// Design Name: 
// Module Name: Debounce
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
    input clk,           // 100 MHz clock
    //input rst,           // Reset (active high)
    input sensor_left,   // Left sensor (active low)
    input sensor_right,  // Right sensor (active low)
    input sensor_T,      // T-sensor (active low)
    input prox1,         // Proximity sensor 1 (active low)
    input prox2,         // Proximity sensor 2 (active low)
    input prox3,  // Limit switch
    output enA,          // Left motor enable
    output enB,          // Right motor enable
    output in1,          // Left motor forward
    output in2,          // Left motor reverse
    output in3,          // Right motor reverse
    output in4,          // Right motor forward
    output pwm_servo,    // Servo PWM
    output mosfet,       // MOSFET control
    output [15:0] led,   // LEDs on Basys 3
    output [6:0] seg,    // Seven-segment segments
    output [3:0] an      // Seven-segment anodes
);
    // Internal wires
    wire [2:0] sensor_status;
    wire [1:0] stateL, stateR;
    wire [3:0] intersection_count;
    wire [2:0] current_state;
    wire done;

    // Instantiate sensor_module
    sensor_module sensors (
        .sensor_left(sensor_left),
        .sensor_right(sensor_right),
        .sensor_T(sensor_T),
        .sensor_status(sensor_status)
    );

    // Instantiate rover_controller
    rover_controller controller (
        .clk(clk),
        //.rst(rst),
        .sensor_status(sensor_status),
        .prox1(prox1),
        .done(done),
        .stateL(stateL),
        .stateR(stateR),
        .intersection_count(intersection_count),
        .current_state(current_state)
    );

    // Instantiate motor_control
    motor_control motors (
        .stateL(stateL),
        .stateR(stateR),
        .enA(enA),
        .enB(enB),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .in4(in4)
    );

    // Instantiate servo_controller
    servo_controller servo (
        .clk(clk),
        //.rst(rst),
        .prox1(prox1),
        .prox2(prox2),
        .pwm_out(pwm_servo),
        .servo_closed(), // Not connected
        .mosfet(mosfet),
        .prox3(prox3),
        .done(done)
    );

    // Instantiate seven_seg_decoder
    seven_seg_decoder decoder (
        .digit(intersection_count),
        .seg(seg)
    );

    // Assign outputs
    assign an = 4'b1110;          // Enable rightmost digit
    assign led[2:0] = current_state; // Show state on LEDs 2:0
    assign led[15:3] = 13'b0;     // Turn off unused LEDs
endmodule