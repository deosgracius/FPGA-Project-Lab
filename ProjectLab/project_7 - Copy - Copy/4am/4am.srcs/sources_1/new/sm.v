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
    reg [2:0] turn_counter = 3'b000;  
    reg mission_complete = 1'b0; // Flag for mission completion

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
            stateL <= 2'b00;
            stateR <= 2'b00;
        end else if (driving_reverse) begin
            // Reverse driving logic
            if (sensor_out[0]) begin  
                stateL <= 2'b10;      
                stateR <= 2'b10;
                mission_complete <= 1'b1; 
            end else begin
                case (sensor_out[3:2]) 
                    2'b11: begin // Both sensors - go straight reverse
                        stateL <= 2'b01; 
                        stateR <= 2'b01; 
                    end
                    2'b10: begin 
                        stateL <= 2'b00; 
                        stateR <= 2'b10; 
                    end
                    2'b01: begin 
                        stateL <= 2'b10;
                        stateR <= 2'b00; 
                    end
                    2'b00: begin 
                        stateL <= 2'b10; 
                        stateR <= 2'b10; 
                    end
                endcase
            end
        end else if (turning_left) begin
            // Continue turning left until both front sensors detect the line again
            if (( (sensor_out[3] &&  sensor_out[2]))) begin
                stateL <= 2'b01;
                stateR <= 2'b01;
                turning_left <= 1'b0;
            end else begin
                stateL <= 2'b10;   
                stateR <= 2'b01;   
            end
        end else if (turning_right) begin
            // Continue turning right until both front sensors detect the line again
            if ((sensor_out[3] && sensor_out[2])) begin
                stateL <= 2'b01;
                stateR <= 2'b01;
                turning_right <= 1'b1;
            end else begin
                stateL <= 2'b01;  
                stateR <= 2'b10;   
            end
         end else if (reverse) begin
                if ((sensor_out[3] && sensor_out[2])) begin
                stateL <= 2'b10;
                stateR <= 2'b10;
                driving_reverse <= 1'b1;
            end else begin
                stateL <= 2'b01;  
                stateR <= 2'b01;   
            end
            end
         
        end else begin
            // Normal line following
            case (sensor_out[3:2]) 
                2'b11: begin 
                    stateL <= 2'b01;
                    stateR <= 2'b01;
                end
                2'b10: begin 
                    stateL <= 2'b01;
                    stateR <= 2'b00;
                end
                2'b01: begin 
                    stateL <= 2'b00;
                    stateR <= 2'b01;
                end
                2'b00: begin 
                    stateL <= 2'b01;
                    stateR <= 2'b01;
                end
            endcase

            // Intersection detection and handling
            if (sensor_out[0]) begin
                case (turn_counter)
                    3'b000: begin  // First intersection - turn left
                        stateL <= 2'b10;
                        stateR <= 2'b01;
                        turning_left <= 1'd0;
                        turn_counter <= turn_counter + 1;
                    end
                    3'b001: begin  // Second intersection - turn right
                        stateL <= 2'b01;
                        stateR <= 2'b10;
                        turning_right <= 1'd1;
                        turn_counter <= turn_counter + 1;
                    end
                    3'b010: begin  // Third intersection - go straight
                        stateL <= 2'b10;
                        stateR <= 2'b10;
                        turn_counter <= turn_counter + 1;
                        reverse <= 1'd2
                    end
                   
                   
                endcase
            end
        end
    end
endmodule