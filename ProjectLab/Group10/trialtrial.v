module line_follower(
    input clk,
    input reset,
    input [3:0] sensor_out,  // from sensor module
    output reg [1:0] stateL,
    output reg [1:0] stateR
);

    // State tracking
    reg turning_left = 1'b0;   // Flag for turning left
    reg turning_right = 1'b0;  // Flag for turning right
    reg driving_reverse = 1'b0; // Flag for reverse driving
    reg [2:0] turn_counter = 3'b000;  // Counter for intersection sequence
    reg mission_complete = 1'b0; // Flag for mission completion

    // Define intersection condition
    wire intersection_detected = sensor_out[0] && sensor_out[3] && sensor_out[2];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stateL <= 2'b00; // Stop
            stateR <= 2'b00; // Stop
            turning_left <= 1'b0;
            turning_right <= 1'b0;
            driving_reverse <= 1'b0;
            turn_counter <= 3'b000;
            mission_complete <= 1'b0;
        end else if (mission_complete) begin
            // Stop all motors when mission is complete
            stateL <= 2'b00;
            stateR <= 2'b00;
        end else if (driving_reverse) begin
            if (intersection_detected) begin  // Fifth intersection detected during reverse
                stateL <= 2'b00;
                stateR <= 2'b00;
                mission_complete <= 1'b1;
            end else begin
                case (sensor_out[3:2]) // Front sensors now used as rear sensors
                    2'b11: begin // Both sensors - go straight reverse
                        stateL <= 2'b10;
                        stateR <= 2'b10;
                    end
                    2'b10: begin // Left sensor - pivot left in reverse
                        stateL <= 2'b00;
                        stateR <= 2'b10;
                    end
                    2'b01: begin // Right sensor - pivot right in reverse
                        stateL <= 2'b10;
                        stateR <= 2'b00;
                    end
                    2'b00: begin // No sensors - maintain reverse
                        stateL <= 2'b10;
                        stateR <= 2'b10;
                    end
                endcase
            end
        end else if (turning_left) begin
            // Complete turn when both front sensors detect the line
            if (sensor_out[3] && sensor_out[2]) begin
                stateL <= 2'b01;
                stateR <= 2'b01;
                turning_left <= 1'b0;
            end else begin
                stateL <= 2'b10;   // Left motor reverse
                stateR <= 2'b01;   // Right motor forward
            end
        end else if (turning_right) begin
            // Complete turn when both front sensors detect the line
            if (sensor_out[3] && sensor_out[2]) begin
                stateL <= 2'b01;
                stateR <= 2'b01;
                turning_right <= 1'b0;
            end else begin
                stateL <= 2'b01;   // Left motor forward
                stateR <= 2'b10;   // Right motor reverse
            end
        end else begin
            // Normal line following when not at intersection
            if (!intersection_detected) begin
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
            end
            
            // Intersection handling - requires all three sensors
            if (intersection_detected) begin
                case (turn_counter)
                    3'b000: begin  // First intersection - turn left
                        stateL <= 2'b10;
                        stateR <= 2'b01;
                        turning_left <= 1'b1;
                        turn_counter <= turn_counter + 1;
                    end
                    3'b001: begin  // Second intersection - turn right
                        stateL <= 2'b01;
                        stateR <= 2'b10;
                        turning_right <= 1'b1;
                        turn_counter <= turn_counter + 1;
                    end
                    3'b010: begin  // Third intersection - go straight
                        stateL <= 2'b01;
                        stateR <= 2'b01;
                        turn_counter <= turn_counter + 1;
                    end
                    3'b011: begin  // Fourth intersection - start reverse
                        stateL <= 2'b10;
                        stateR <= 2'b10;
                        driving_reverse <= 1'b1;
                        turn_counter <= turn_counter + 1;
                    end
                endcase
            end
        end
    end
endmodule