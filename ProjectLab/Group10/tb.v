module ln(
    input clk,
    input reset,
    input [3:0] sensor_out,  // from sensor module
    output reg [1:0] stateL,
    output reg [1:0] stateR
);

    reg turning_left = 1'b0;
    reg turning_right = 1'b0;
    reg [1:0] turn_counter = 2'b00;  // Counter for intersection sequence

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stateL <= 2'b00; // Stop
            stateR <= 2'b00; // Stop
            turning_left <= 1'b0;
            turning_right <= 1'b0;
            turn_counter <= 2'b00;
        end else begin
            if (turning_left) begin
                // Continue turning left until line is detected again
                if (sensor_out[3] && sensor_out[2]) begin
                    stateL <= 2'b01;
                    stateR <= 2'b01;
                    turning_left <= 1'b0;
                end else begin
                    stateL <= 2'b10;
                    stateR <= 2'b01;
                end
            end else if (turning_right) begin
                // Continue turning right until line is detected again
                if (sensor_out[3] && sensor_out[2]) begin
                    stateL <= 2'b01;
                    stateR <= 2'b01;
                    turning_right <= 1'b0;
                end else begin
                    stateL <= 2'b01;
                    stateR <= 2'b10;
                end
            end else begin
                // Normal line-following operation
                case (sensor_out[3:2])
                    2'b11: begin stateL <= 2'b01; stateR <= 2'b01; end // Go straight
                    2'b10: begin stateL <= 2'b01; stateR <= 2'b00; end // Pivot right
                    2'b01: begin stateL <= 2'b00; stateR <= 2'b01; end // Pivot left
                    2'b00: begin stateL <= 2'b01; stateR <= 2'b01; end // Maintain forward
                endcase

                // Detect intersection and decide action
                if (sensor_out[3] && sensor_out[2]) begin
                    case (turn_counter)
                        2'b00: begin  // First intersection - turn left
                            stateL <= 2'b10;
                            stateR <= 2'b01;
                            turning_left <= 1'b1;
                            turn_counter <= turn_counter + 1;
                        end
                        2'b01: begin  // Second intersection - turn right
                            stateL <= 2'b01;
                            stateR <= 2'b10;
                            turning_right <= 1'b1;
                            turn_counter <= turn_counter + 1;
                        end
                    endcase
                end
            end
        end
    end
endmodule