`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2025 08:33:26 PM
// Design Name: 
// Module Name: Rover_Controller_m
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Rover controller for line following with right turn at T-intersection
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module rover_controller (
    input clk,                  // Clock input
    input rst,                  // Reset input (active high)
    input [2:0] sensor_status,  // [left, right, T] from sensor_module
    input prox1,                // Proximity sensor 1 (active low)
    input done,                 // Done signal from servo_controller
    output reg [1:0] stateL,    // Left motor state
    output reg [1:0] stateR,    // Right motor state
    output reg [3:0] intersection_count, // Intersection counter
    output [2:0] current_state  // Current state for LEDs
);
    // Define states using parameters
    parameter STOP = 3'b000;
    parameter LINE_FOLLOW = 3'b001;
    parameter STOP_RIGHT = 3'b010;
    parameter INIT_TURN_RIGHT = 3'b011;
    parameter ADJUST_TURN = 3'b100;
    parameter REVERSE = 3'b101;
    parameter SERVO_WAIT = 3'b110;      // New state: wait for servo actions
    parameter REVERSE_LINE_FOLLOW = 3'b111; // New state: reverse line following

    // State register
    reg [2:0] state;
    reg after_turn; // Flag to indicate post-right-turn line following

    // Assign current state to output for LEDs
    assign current_state = state;

    // Sequential logic for state transitions
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STOP;
            after_turn <= 0;
            intersection_count <= 0;
        end else begin
            case (state)
                STOP: begin
                    if (sensor_status[2:1] != 2'b00) begin
                        state <= LINE_FOLLOW;
                    end
                    after_turn <= 0;
                    // intersection_count retains its value
                end
                LINE_FOLLOW: begin
                    if (after_turn == 1 && ~prox1) begin
                        state <= SERVO_WAIT; // Prox1 triggers servo actions
                    end else if (sensor_status[0] == 1'b1) begin
                        state <= STOP_RIGHT;
                    end else if (sensor_status[2:1] == 2'b00) begin
                        state <= REVERSE;
                    end
                end
                STOP_RIGHT: begin
                    state <= INIT_TURN_RIGHT;
                end
                INIT_TURN_RIGHT: begin
                    state <= ADJUST_TURN;
                end
                ADJUST_TURN: begin
                    if (sensor_status[2:1] == 2'b11) begin
                        state <= LINE_FOLLOW;
                        after_turn <= 1; // Set flag after right turn
                        intersection_count <= intersection_count + 1; // Increment counter
                    end
                end
                REVERSE: begin
                    if (sensor_status[2:1] != 2'b00) begin
                        state <= LINE_FOLLOW;
                    end
                end
                SERVO_WAIT: begin
                    if (done) begin
                        state <= REVERSE_LINE_FOLLOW; // Servo done, start reverse
                    end
                end
                REVERSE_LINE_FOLLOW: begin
                    if (sensor_status[0] == 1'b1) begin
                        state <= STOP; // Stop at intersection
                    end
                end
            endcase
        end
    end

    // Combinational logic for motor outputs
    always @(*) begin
        case (state)
            STOP: begin
                stateL = 2'b00;  // Stop
                stateR = 2'b00;
            end
            LINE_FOLLOW: begin
                case (sensor_status[2:1])
                    2'b11: begin
                        stateL = 2'b10;  // Forward (corrected)
                        stateR = 2'b10;
                    end
                    2'b10: begin
                        stateL = 2'b10;  // Forward
                        stateR = 2'b00;  // Stop (turn right)
                    end
                    2'b01: begin
                        stateL = 2'b00;  // Stop
                        stateR = 2'b10;  // Forward (turn left)
                    end
                    2'b00: begin
                        stateL = 2'b01;
                        stateR = 2'b01;
                    end
                    default: begin
                        stateL = 2'b00;
                        stateR = 2'b00;
                    end
                endcase
            end
            STOP_RIGHT: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
            INIT_TURN_RIGHT: begin
                stateL = 2'b10;  // Forward
                stateR = 2'b01;  // Reverse (sharp right turn)
            end
            ADJUST_TURN: begin
                case (sensor_status[2:1])
                    2'b00: begin
                        stateL = 2'b01;  // Forward
                        stateR = 2'b10;  // Reverse
                    end
                    2'b10: begin
                        stateL = 2'b10;  // Forward
                        stateR = 2'b00;  // Stop
                    end
                    2'b01: begin
                        stateL = 2'b00;  // Stop
                        stateR = 2'b10;  // Forward
                    end
                    2'b11: begin
                        stateL = 2'b10;  // Forward
                        stateR = 2'b10;  // Forward
                    end
                endcase
            end
            REVERSE: begin
                stateL = 2'b01;  // Reverse (corrected)
                stateR = 2'b01;
            end
            SERVO_WAIT: begin
                stateL = 2'b00;  // Stop while servo acts
                stateR = 2'b00;
            end
            REVERSE_LINE_FOLLOW: begin
                case (sensor_status[2:1])
                    2'b11: begin
                        stateL = 2'b01;  // Reverse
                        stateR = 2'b01;
                    end
                    2'b10: begin
                        stateL = 2'b01;  // Stop
                        stateR = 2'b00;  // Reverse (turn left)
                    end
                    2'b01: begin
                        stateL = 2'b00;  // Reverse
                        stateR = 2'b01;  // Stop (turn right)
                    end
                    2'b00: begin
                        stateL = 2'b10;  // Reverse
                        stateR = 2'b10;
                    end
                endcase
            end
        endcase
    end
endmodule