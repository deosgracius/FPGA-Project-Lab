module line_follower(
    input clk,
    input reset,
    input [3:0] sensor_out,  // from sensor module
    output reg [1:0] stateL,
    output reg [1:0] stateR
);

    reg turning_left = 1'b0;  // Flag to keep track of turning left state

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stateL <= 2'b00; // Stop
            stateR <= 2'b00; // Stop
            turning_left <= 1'b0;
        end else begin
            if (turning_left) begin
                // Continue turning left until both front sensors detect the line again
                if (sensor_out[3] && sensor_out[2]) begin
                    // Turn complete, go back to normal line following
                    stateL <= 2'b01;
                    stateR <= 2'b01;
                    turning_left <= 1'b0;  // Reset the flag
                end else begin
                    // Keep turning left regardless of sensor[1]
                    stateL <= 2'b10;   // Stop left motor
                    stateR <= 2'b01;   // Right motor forward
                end
            end else begin
                case (sensor_out[3:2]) // Front sensors behavior
                    2'b11: begin // Both front sensors - go straight
                        stateL <= 2'b01;
                        stateR <= 2'b01;
                    end
                    2'b10: begin // Left sensor only - pivot right
                        stateL <= 2'b01;
                        stateR <= 2'b00;
                    end
                    2'b01: begin // Right sensor only - pivot left
                        stateL <= 2'b00;
                        stateR <= 2'b01;
                    end
                    2'b00: begin // No sensors - maintain forward
                        stateL <= 2'b01;
                        stateR <= 2'b01;
                    end
                endcase

                // Start turning left if the back middle sensor detects metal but left side does not
                if (sensor_out[0] && ~sensor_out[1]) begin
                    stateL <= 2'b10; // Stop left motor
                    stateR <= 2'b01; // Right motor forward to turn left
                    turning_left <= 1'b1; // Set flag to start turning
                end
            end
        end
    end
endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2025 04:12:44 AM
// Design Name: 
// Module Name: sm
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


module line_follower(
    input clk,
    input reset,
    input [3:0] sensor_out,  // from sensor module
    output reg [1:0] stateL,
    output reg [1:0] stateR
);

    parameter KP = 10;  // Proportional gain
    parameter KI = 1;   // Integral gain
    parameter KD = 5;   // Derivative gain

    reg turning_left = 1'b0;  // Flag to keep track of turning left state
    reg signed [15:0] error = 16'd0;
    reg signed [15:0] last_error = 16'd0;
    reg signed [15:0] integral = 16'd0;
    reg signed [15:0] derivative = 16'd0;
    reg signed [15:0] pid_output = 16'd0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stateL <= 2'b00; // Stop
            stateR <= 2'b00; // Stop
            turning_left <= 1'b0;
            error <= 16'd0;
            last_error <= 16'd0;
            integral <= 16'd0;
            derivative <= 16'd0;
            pid_output <= 16'd0;
        end else begin
            if (turning_left) begin
                // Continue turning left until both front sensors detect the line again
                if (sensor_out[3] && sensor_out[2]) begin
                    // Turn complete, go back to normal line following
                    stateL <= 2'b01;
                    stateR <= 2'b01;
                    turning_left <= 1'b0;  // Reset the flag
                end else begin
                    // Keep turning left
                    stateL <= 2'b00;   // Stop left motor
                    stateR <= 2'b01;   // Right motor forward
                end
            end else begin
                // Calculate error based on sensor readings
                if (sensor_out[3] && sensor_out[2]) begin
                    error <= 16'd0; // Line centered
                end else if (sensor_out[3]) begin
                    error <= -16'd100; // Line on left side (adjust value based on sensitivity)
                end else if (sensor_out[2]) begin
                    error <= 16'd100; // Line on right side
                end else begin
                    error <= last_error; // Maintain last error if no line detected
                end

                // PID calculation
                integral <= integral + error; // Integral term, ensure it doesn't wind up too much
                derivative <= error - last_error; // Derivative term
                
                // Compute PID output
                pid_output <= (KP * error) + (KI * integral) + (KD * derivative);
                
                last_error <= error; // Update for next cycle

                // Apply PID for motor control
                case (sensor_out[3:2])
                    2'b11: begin // Both front sensors - go straight
                        stateL <= (pid_output < 0) ? 2'b01 : 2'b00; // Adjust left motor
                        stateR <= (pid_output > 0) ? 2'b01 : 2'b00; // Adjust right motor
                    end
                    2'b10: begin // Left sensor only - pivot right
                        stateL <= 2'b01;
                        stateR <= 2'b00;
                    end
                    2'b01: begin // Right sensor only - pivot left
                        stateL <= 2'b00;
                        stateR <= 2'b01;
                    end
                    2'b00: begin // No sensors - maintain forward
                        stateL <= 2'b01;
                        stateR <= 2'b01;
                    end
                endcase

                // Start turning left if the back middle sensor detects metal but left side does not
                if (sensor_out[0] && ~sensor_out[1]) begin
                    stateL <= 2'b00; // Stop left motor
                    stateR <= 2'b01; // Right motor forward to turn left
                    turning_left <= 1'b1; // Set flag to start turning
                end
            end
        end
    end
endmodule
