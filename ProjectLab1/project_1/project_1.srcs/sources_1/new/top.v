`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/21/2025 12:10:05 PM
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
    input wire clk,                    // System clock
    input wire reset,                  // Reset button
    input wire [1:0] front_sensors,    // 2 front sensors for line detection
    input wire back_sensor,            // 1 back sensor
    output reg [1:0] motor_left,       // Left motor control (00:stop, 01:reverse, 10:forward)
    output reg [1:0] motor_right       // Right motor control (00:stop, 01:reverse, 10:forward)
);

    // State definitions
    parameter FOLLOWING_LINE = 3'd0;
    parameter TURNING_LEFT = 3'd1;
    parameter TURNING_RIGHT = 3'd2;
    parameter GOING_STRAIGHT = 3'd3;
    parameter REVERSING = 3'd4;
    parameter STOPPED = 3'd5;

    // Motor control parameters
    parameter MOTOR_STOP = 2'b00;
    parameter MOTOR_REVERSE = 2'b01;
    parameter MOTOR_FORWARD = 2'b10;

    // State registers
    reg [2:0] current_state;
    reg [2:0] intersection_counter;
    
    // Debounce counter for intersection detection
    reg [19:0] debounce_counter;
    reg intersection_detected;
    reg last_intersection;

    // Turn completion timer
    reg [19:0] turn_timer;
    parameter TURN_DURATION = 20'd100000; // Adjust based on your clock frequency

    // Intersection detection logic
    wire is_intersection = (front_sensors == 2'b11) && back_sensor;
    
    // Debouncing process
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            debounce_counter <= 0;
            intersection_detected <= 0;
            last_intersection <= 0;
        end else begin
            if (is_intersection && !last_intersection) begin
                if (debounce_counter == 20'd50000) begin // Adjust threshold as needed
                    intersection_detected <= 1;
                    debounce_counter <= 0;
                end else begin
                    debounce_counter <= debounce_counter + 1;
                end
            end else begin
                debounce_counter <= 0;
                intersection_detected <= 0;
            end
            last_intersection <= is_intersection;
        end
    end

    // Main state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= FOLLOWING_LINE;
            intersection_counter <= 0;
            motor_left <= MOTOR_STOP;
            motor_right <= MOTOR_STOP;
            turn_timer <= 0;
        end else begin
            case (current_state)
                FOLLOWING_LINE: begin
                    // Basic line following logic
                    case (front_sensors)
                        2'b10: begin // Line under left sensor
                            motor_left <= MOTOR_FORWARD;
                            motor_right <= MOTOR_STOP;
                        end
                        2'b01: begin // Line under right sensor
                            motor_left <= MOTOR_STOP;
                            motor_right <= MOTOR_FORWARD;
                        end
                        2'b11: begin // Line under both sensors
                            motor_left <= MOTOR_FORWARD;
                            motor_right <= MOTOR_FORWARD;
                        end
                        default: begin // No line detected
                            motor_left <= MOTOR_FORWARD;
                            motor_right <= MOTOR_FORWARD;
                        end
                    endcase

                    // Intersection handling
                    if (intersection_detected) begin
                        case (intersection_counter)
                            3'd0: current_state <= TURNING_LEFT;
                            3'd1: current_state <= TURNING_RIGHT;
                            3'd2: current_state <= GOING_STRAIGHT;
                            3'd3: current_state <= REVERSING;
                            3'd4: current_state <= STOPPED;
                            default: current_state <= STOPPED;
                        endcase
                        intersection_counter <= intersection_counter + 1;
                        turn_timer <= 0;
                    end
                end

                TURNING_LEFT: begin
                    motor_left <= MOTOR_REVERSE;
                    motor_right <= MOTOR_FORWARD;
                    if (turn_timer == TURN_DURATION) begin
                        current_state <= FOLLOWING_LINE;
                        turn_timer <= 0;
                    end else begin
                        turn_timer <= turn_timer + 1;
                    end
                end

                TURNING_RIGHT: begin
                    motor_left <= MOTOR_FORWARD;
                    motor_right <= MOTOR_REVERSE;
                    if (turn_timer == TURN_DURATION) begin
                        current_state <= FOLLOWING_LINE;
                        turn_timer <= 0;
                    end else begin
                        turn_timer <= turn_timer + 1;
                    end
                end

                GOING_STRAIGHT: begin
                    motor_left <= MOTOR_FORWARD;
                    motor_right <= MOTOR_FORWARD;
                    if (turn_timer == TURN_DURATION) begin
                        current_state <= FOLLOWING_LINE;
                        turn_timer <= 0;
                    end else begin
                        turn_timer <= turn_timer + 1;
                    end
                end

                REVERSING: begin
                    motor_left <= MOTOR_REVERSE;
                    motor_right <= MOTOR_REVERSE;
                    if (intersection_detected) begin
                        current_state <= STOPPED;
                    end
                end

                STOPPED: begin
                    motor_left <= MOTOR_STOP;
                    motor_right <= MOTOR_STOP;
                end

                default: begin
                    current_state <= FOLLOWING_LINE;
                end
            endcase
        end
    end
endmodule
