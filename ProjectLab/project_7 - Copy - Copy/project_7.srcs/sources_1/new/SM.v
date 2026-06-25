module state_machine(
    input clk,
    input rst,
    input [3:0] sensor_out, // [3]: Msensor1 (front left); [2]: Msensor2 (front right); [1]: Lsensor (left side); [0]: Rsensor (back middle)
    output reg [1:0] stateL, // Left motor command (2'b01 = forward, 2'b00 = stop, 2'b10 = reverse)
    output reg [1:0] stateR, // Right motor command
    output reg [7:0] counter // 8-bit counter for tracking state duration
);

    // State encoding
    localparam LINE_FOLLOW_FWD  = 3'b000;
    localparam LINE_FOLLOW_REV  = 3'b001;
    localparam TURN_LEFT        = 3'b010;
    localparam TURN_RIGHT       = 3'b011;
    localparam GO_STRAIGHT      = 3'b100;
    localparam REVERSE          = 3'b101;

    reg [2:0] current_state, next_state;

    // Detect when front sensors find the line during turns
    wire front_sensors_detect;
    assign front_sensors_detect = sensor_out[3] || sensor_out[2];

    // Counter logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 8'd0;
        end else if (current_state != next_state) begin
            // Reset counter on state change
            counter <= 8'd0;
        end else begin
            // Increment counter while in the same state
            counter <= counter + 1;
        end
    end

    // Sequential Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= LINE_FOLLOW_FWD;
        end else begin
            current_state <= next_state;
        end
    end

    // Next-State Logic
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            LINE_FOLLOW_FWD: begin
                if (sensor_out[1]) begin // If Lsensor detects
                    // State transition logic will be determined by an external signal
                    // For now, default to TURN_LEFT
                    next_state = TURN_LEFT;
                end
            end

            LINE_FOLLOW_REV: begin
                // Stay in reverse line following
                next_state = LINE_FOLLOW_REV;
            end

            TURN_LEFT: begin
                if (front_sensors_detect)
                    next_state = LINE_FOLLOW_FWD;
            end

            TURN_RIGHT: begin
                if (front_sensors_detect)
                    next_state = LINE_FOLLOW_FWD;
            end

            GO_STRAIGHT: begin
                next_state = LINE_FOLLOW_FWD;
            end

            REVERSE: begin
                next_state = LINE_FOLLOW_REV;
            end

            default: next_state = LINE_FOLLOW_FWD;
        endcase
    end

    // Output Logic
    always @(*) begin
        // Default outputs
        stateL = 2'b00;
        stateR = 2'b00;

        case (current_state)
            LINE_FOLLOW_FWD: begin
                case (sensor_out[3:2])
                    2'b11: begin // Both front sensors - go straight
                        stateL = 2'b01;
                        stateR = 2'b01;
                    end
                    2'b10: begin // Left sensor only - pivot right
                        stateL = 2'b01;
                        stateR = 2'b00;
                    end
                    2'b01: begin // Right sensor only - pivot left
                        stateL = 2'b00;
                        stateR = 2'b01;
                    end
                    2'b00: begin // No sensors - maintain forward
                        stateL = 2'b01;
                        stateR = 2'b01;
                    end
                endcase
            end

            LINE_FOLLOW_REV: begin
                if (!sensor_out[0]) begin // If back sensor (Rsensor) doesn't detect
                    case (sensor_out[3:2])
                        2'b11: begin // Both front sensors detect
                            stateL = 2'b10;
                            stateR = 2'b10;
                        end
                        2'b10: begin // Left sensor only - stop left, reverse right
                            stateL = 2'b00;
                            stateR = 2'b10;
                        end
                        2'b01: begin // Right sensor only - reverse left, stop right
                            stateL = 2'b10;
                            stateR = 2'b00;
                        end
                        2'b00: begin // No sensors detect - maintain reverse
                            stateL = 2'b10;
                            stateR = 2'b10;
                        end
                    endcase
                end else begin
                    // Back sensor detects - continue reverse
                    stateL = 2'b10;
                    stateR = 2'b10;
                end
            end

            TURN_LEFT: begin
                // Left motor stop, Right motor forward
                stateL = 2'b00;
                stateR = 2'b01;
            end

            TURN_RIGHT: begin
                // Right motor stop, Left motor forward
                stateL = 2'b01;
                stateR = 2'b00;
            end

            GO_STRAIGHT: begin
                // Both motors forward
                stateL = 2'b01;
                stateR = 2'b01;
            end

            REVERSE: begin
                // Both motors reverse
                stateL = 2'b10;
                stateR = 2'b10;
            end
        endcase
    end

endmodule
