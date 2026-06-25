module state_machine(
    input clk,
    input rst,
    input [3:0] sensor_out, // [3]: Msensor1 (front left); [2]: Msensor2 (front right); [1]: Lsensor (left side); [0]: Rsensor (back middle)
    output reg [1:0] stateL, // Left motor command (2'b01 = forward, 2'b00 = stop, 2'b10 = reverse)
    output reg [1:0] stateR, // Right motor command
    output reg [7:0] counter
);
    // State encoding
    localparam LINE_FOLLOW_FWD  = 3'b000;
    localparam LINE_FOLLOW_REV  = 3'b001;
    localparam TURN_LEFT        = 3'b010;
    localparam TURN_RIGHT       = 3'b011;
    localparam GO_STRAIGHT      = 3'b100;
    localparam STOP            = 3'b101;

    reg [2:0] current_state, next_state;
    reg [2:0] intersection_count;
    reg intersection_detected;

    // Detect when front sensors find the line during turns
    wire front_sensors_detect;
    assign front_sensors_detect = sensor_out[3] || sensor_out[2];

    // Intersection detection and counting logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intersection_count <= 3'd0;
            intersection_detected <= 1'b0;
        end else begin
            // If Lsensor detects and we haven't counted this intersection yet
            if (sensor_out[1] && !intersection_detected) begin
                intersection_count <= intersection_count + 1;
                intersection_detected <= 1'b1;
            end
            // Reset detection flag when Lsensor is inactive
            else if (!sensor_out[1]) begin
                intersection_detected <= 1'b0;
            end
        end
    end

    // Counter logic for timing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 8'd0;
        end else if (current_state != next_state) begin
            counter <= 8'd0;
        end else begin
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
                    case (intersection_count)
                        3'd1: next_state = TURN_LEFT;
                        3'd2: next_state = TURN_RIGHT;
                        3'd3: next_state = GO_STRAIGHT;
                        3'd4: next_state = LINE_FOLLOW_REV;
                        3'd5: next_state = STOP;
                        default: next_state = LINE_FOLLOW_FWD;
                    endcase
                end
            end

            LINE_FOLLOW_REV: begin
                if (!sensor_out[0]) begin // If back sensor doesn't detect
                    if (front_sensors_detect) // And front sensors detect
                        next_state = LINE_FOLLOW_REV; // Stay in reverse
                end
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

            STOP: begin
                next_state = STOP; // Stay stopped
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
                if (!sensor_out[0]) begin // If back sensor doesn't detect
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
                // Left motor stop, Right motor forward until front sensors detect
                stateL = 2'b00;
                stateR = 2'b01;
            end

            TURN_RIGHT: begin
                // Right motor stop, Left motor forward until front sensors detect
                stateL = 2'b01;
                stateR = 2'b00;
            end

            GO_STRAIGHT: begin
                // Both motors forward
                stateL = 2'b01;
                stateR = 2'b01;
            end

            STOP: begin
                // Both motors stop
                stateL = 2'b00;
                stateR = 2'b00;
            end
        endcase
    end

endmodule