`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2025 06:48:10 PM
// Design Name: 
// Module Name: StateCases
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



// State Cases Module
module State_cases(
    input wire clk,
    input wire reset,
    input wire sensor_west,
    input wire sensor_east,
    output reg [3:0] counter, // 4-bit counter for intersections
    output reg motor_enable_a,
    output reg motor_enable_b,
    output reg in1,
    output reg in2,
    output reg in3,
    output reg in4
);
    // State definitions
    parameter TURN_LEFT  = 3'b001;
    parameter TURN_RIGHT = 3'b010;
    parameter FORWARD    = 3'b011;
    parameter REVERSE    = 3'b100;
    parameter STOP       = 3'b101;

    reg [2:0] current_task;

    always @(posedge clk or posedge reset) begin
        case (reset)
            1'b1: begin
                // Reset state
                counter         <= 0;
                motor_enable_a  <= 1;
                motor_enable_b  <= 1;
                // Forward by default
                in1 <= 0;
                in2 <= 1;
                in3 <= 0;
                in4 <= 1;
                current_task    <= TURN_LEFT;
            end

            // Normal operation when reset = 0
            default: begin
                case ({sensor_west, sensor_east})
                    2'b10: begin // Only left sensor is on
                        motor_enable_a <= 0; // Turn off left motor
                        motor_enable_b <= 1; // Keep right motor on
                        in1 <= 0;
                        in2 <= 0;
                        in3 <= 0;
                        in4 <= 1;
                    end

                    2'b01: begin // Only right sensor is on
                        motor_enable_a <= 1; // Keep left motor on
                        motor_enable_b <= 0; // Turn off right motor
                        in1 <= 0;
                        in2 <= 1;
                        in3 <= 0;
                        in4 <= 0;
                    end

                    2'b11: begin // Intersection detected
                        counter <= counter + 1;
                        case (current_task)
                            TURN_LEFT: begin
                                in1 <= 1;
                                in2 <= 1;
                                in3 <= 0;
                                in4 <= 1;
                                current_task <= TURN_RIGHT;
                            end
                            TURN_RIGHT: begin
                                in1 <= 0;
                                in2 <= 1;
                                in3 <= 1;
                                in4 <= 1;
                                current_task <= FORWARD;
                            end
                            FORWARD: begin
                                in1 <= 0;
                                in2 <= 1;
                                in3 <= 0;
                                in4 <= 1;
                                current_task <= REVERSE;
                            end
                            REVERSE: begin
                                in1 <= 1;
                                in2 <= 0;
                                in3 <= 1;
                                in4 <= 0;
                                current_task <= STOP;
                            end
                            STOP: begin
                                in1 <= 1;
                                in2 <= 1;
                                in3 <= 1;
                                in4 <= 1;
                            end
                        endcase
                    end

                    default: begin // No sensors active => move forward
                        in1 <= 0;
                        in2 <= 1;
                        in3 <= 0;
                        in4 <= 1;
                    end
                endcase
            end
        endcase
    end
endmodule
