module autonomous_robot (
    input clk,             // Clock signal
    input [2:0] sensor,    // 3-bit sensor input (L2, L1, L0)
    output reg [2:0] motor, // Motor control (M2, M1, M0)
    output reg reverse,    // Reverse flag
    output reg [3:0] state // FSM state output for debugging
);

    // State Encoding
    parameter STATE_FOLLOW = 4'd0;
    parameter STATE_TURN_RIGHT = 4'd1;
    parameter STATE_TURN_LEFT = 4'd2;
    parameter STATE_STOP = 4'd3;
    parameter STATE_DELAY = 4'd4;
    parameter STATE_REVERSE = 4'd5;
    
    // Intersection counter
    reg [1:0] intersection_count = 2'b00;
    
    // Delay counter for intersection detection
    reg [24:0] delay_counter = 25'd0;
    parameter INTERSECTION_DELAY = 25'd100_000_000; // 1 second delay at 100MHz
    
    // Current and next state registers
    reg [3:0] current_state = STATE_FOLLOW;
    reg [3:0] next_state = STATE_FOLLOW;

    // Motor control patterns (M2, M1, M0)
    parameter [2:0] FORWARD = 3'b000;      // Both motors forward
    parameter [2:0] SLIGHT_RIGHT = 3'b001; // Slight right correction
    parameter [2:0] SLIGHT_LEFT = 3'b010;  // Slight left correction
    parameter [2:0] TURN_RIGHT = 3'b110;   // Hard right turn
    parameter [2:0] TURN_LEFT = 3'b101;    // Hard left turn
    parameter [2:0] STOP = 3'b111;         // Stop motors
    
    // Sensor pattern parameters
    parameter [2:0] ALL_SENSORS = 3'b111;  // Intersection detected
    parameter [2:0] CENTER_SENSOR = 3'b010; // Center on line
    parameter [2:0] RIGHT_SENSOR = 3'b100;  // Drifting left
    parameter [2:0] LEFT_SENSOR = 3'b001;   // Drifting right

    // Synchronize sensor inputs
    reg [2:0] sensor_sync;
    always @(posedge clk) begin
        sensor_sync <= sensor;
    end

    // State Transition Logic and Output Logic
    always @(posedge clk) begin
        current_state <= next_state;
        state <= current_state;
        
        case (current_state)
            STATE_FOLLOW: begin
                reverse <= 1'b0;
                case (sensor_sync)
                    LEFT_SENSOR: motor <= SLIGHT_RIGHT;
                    RIGHT_SENSOR: motor <= SLIGHT_LEFT;
                    CENTER_SENSOR: motor <= FORWARD;
                    ALL_SENSORS: begin
                        motor <= FORWARD;
                        next_state <= STATE_DELAY;
                        delay_counter <= 25'd0;
                    end
                    default: motor <= FORWARD;
                endcase
            end
            
            STATE_DELAY: begin
                delay_counter <= delay_counter + 1;
                
                if (delay_counter >= INTERSECTION_DELAY) begin
                    case (intersection_count)
                        2'b00: begin
                            next_state <= STATE_TURN_LEFT;
                            intersection_count <= intersection_count + 1;
                        end
                        2'b01: begin
                            next_state <= STATE_TURN_RIGHT;
                            intersection_count <= intersection_count + 1;
                        end
                        2'b10: begin
                            next_state <= STATE_FOLLOW; // Go straight
                            intersection_count <= intersection_count + 1;
                        end
                        2'b11: begin
                            next_state <= STATE_REVERSE;
                            intersection_count <= intersection_count + 1;
                        end
                        default: next_state <= STATE_STOP;
                    endcase
                end else begin
                    motor <= FORWARD;
                    next_state <= STATE_DELAY;
                end
            end

            STATE_TURN_RIGHT: begin
                motor <= TURN_RIGHT;
                if (sensor_sync == CENTER_SENSOR) begin
                    next_state <= STATE_FOLLOW;
                end else begin
                    next_state <= STATE_TURN_RIGHT;
                end
            end

            STATE_TURN_LEFT: begin
                motor <= TURN_LEFT;
                if (sensor_sync == CENTER_SENSOR) begin
                    next_state <= STATE_FOLLOW;
                end else begin
                    next_state <= STATE_TURN_LEFT;
                end
            end

            STATE_STOP: begin
                motor <= STOP;
                next_state <= STATE_STOP;
            end

            STATE_REVERSE: begin
                reverse <= 1'b1;
                motor <= FORWARD; // In reverse mode, forward command means reverse driving
                if (sensor_sync == ALL_SENSORS) begin // If intersection detected again
                    next_state <= STATE_STOP;
                end else begin
                    next_state <= STATE_REVERSE;
                end
            end

            default: begin
                next_state <= STATE_FOLLOW;
                motor <= FORWARD;
                reverse <= 1'b0;
            end
        endcase
    end
endmodule