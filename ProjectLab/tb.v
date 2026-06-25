// Sensor Module with encoded states
module sensor_behavior(
    input wire sensor_west,         // Left sensor
    input wire sensor_east,         // Right sensor
    output reg [1:0] sensor_state   // Combined sensor state
);
    // Sensor State Encodings
    parameter NO_LINE      = 2'b00;     // Neither sensor detects line
    parameter RIGHT_ONLY   = 2'b01;     // Only right sensor detects line
    parameter LEFT_ONLY    = 2'b10;     // Only left sensor detects line
    parameter INTERSECTION = 2'b11;     // Both sensors detect line

    // Truth Table Implementation
    //-----------------------------
    // sensor_west | sensor_east | sensor_state
    //     0       |     0       |    NO_LINE
    //     0       |     1       |    RIGHT_ONLY
    //     1       |     0       |    LEFT_ONLY
    //     1       |     1       |    INTERSECTION
    //-----------------------------

    always @(sensor_west, sensor_east)
        case({sensor_west, sensor_east})
            2'b00   :   sensor_state = NO_LINE;
            2'b01   :   sensor_state = RIGHT_ONLY;
            2'b10   :   sensor_state = LEFT_ONLY;
            2'b11   :   sensor_state = INTERSECTION;
        endcase
endmodule

// Motor Control Module with encoded control signals
module motor_control(
    input wire [3:0] control_signals,    // Input from state machine
    output wire enable_a,                // Motor 1 enable
    output wire enable_b,                // Motor 2 enable
    output reg [1:0] motor1_control,     // Motor 1: {In1,In3}
    output reg [1:0] motor2_control      // Motor 2: {In2,In4}
);
    // Motor Control Signal Encodings
    parameter MOVE_FORWARD  = 4'b0101;   // Both motors forward
    parameter TURN_LEFT    = 4'b1101;   // M1 stop, M2 forward
    parameter TURN_RIGHT   = 4'b0111;   // M1 forward, M2 stop
    parameter MOVE_REVERSE = 4'b1010;   // Both motors reverse
    parameter FULL_STOP    = 4'b1111;   // Both motors stop

    // Motor State Encodings
    parameter M1_FORWARD   = 2'b00;     // Motor 1 forward (In1=0,In3=0)
    parameter M1_STOP      = 2'b11;     // Motor 1 stop (In1=1,In3=1)
    parameter M1_REVERSE   = 2'b11;     // Motor 1 reverse (In1=1,In3=1)
    parameter M1_TURN      = 2'b10;     // Motor 1 turn mode (In1=1,In3=0)
    
    parameter M2_FORWARD   = 2'b11;     // Motor 2 forward (In2=1,In4=1)
    parameter M2_STOP      = 2'b11;     // Motor 2 stop (In2=1,In4=1)
    parameter M2_REVERSE   = 2'b00;     // Motor 2 reverse (In2=0,In4=0)

    // Motors always enabled
    assign enable_a = 1'b1;
    assign enable_b = 1'b1;

    // Motor Control Truth Table Implementation
    always @(control_signals)
        case(control_signals)
            MOVE_FORWARD : begin
                motor1_control = M1_FORWARD;
                motor2_control = M2_FORWARD;
            end
            TURN_LEFT   : begin
                motor1_control = M1_TURN;
                motor2_control = M2_FORWARD;
            end
            TURN_RIGHT  : begin
                motor1_control = M1_FORWARD;
                motor2_control = M2_STOP;
            end
            MOVE_REVERSE : begin
                motor1_control = M1_REVERSE;
                motor2_control = M2_REVERSE;
            end
            FULL_STOP   : begin
                motor1_control = M1_STOP;
                motor2_control = M2_STOP;
            end
            default    : begin
                motor1_control = M1_STOP;
                motor2_control = M2_STOP;
            end
        endcase
endmodule

// State Machine Module with encoded states and tasks
module state_machine(
    input wire clock,                    // System clock
    input wire reset,                    // Reset signal
    input wire [1:0] sensor_state,       // Input from sensor module
    output reg [3:0] control_signals,    // Output to motor control
    output reg [2:0] intersection_counter // Intersection counter
);
    // State Machine State Encodings
    parameter FOLLOW_LINE   = 3'b001;    // Normal line following
    parameter ADJUST_LEFT   = 3'b010;    // Correcting to the left
    parameter ADJUST_RIGHT  = 3'b100;    // Correcting to the right

    // Sensor State Encodings (matching sensor_behavior module)
    parameter NO_LINE      = 2'b00;
    parameter RIGHT_ONLY   = 2'b01;
    parameter LEFT_ONLY    = 2'b10;
    parameter INTERSECTION = 2'b11;

    // Movement Command Encodings (matching motor_control module)
    parameter MOVE_FORWARD  = 4'b0101;
    parameter TURN_LEFT    = 4'b1101;
    parameter TURN_RIGHT   = 4'b0111;
    parameter MOVE_REVERSE = 4'b1010;
    parameter FULL_STOP    = 4'b1111;

    // Task Counter States
    parameter TASK_1       = 3'b000;    // First intersection: Turn left
    parameter TASK_2       = 3'b001;    // Second intersection: Turn right
    parameter TASK_3       = 3'b010;    // Third intersection: Forward
    parameter TASK_4       = 3'b011;    // Fourth intersection: Reverse
    parameter TASK_5       = 3'b100;    // Fifth intersection: Stop
    
    reg [2:0] current_state;

    // State Machine Logic
    always @(posedge clock)
        case(reset)
            1'b1: begin
                current_state = FOLLOW_LINE;
                intersection_counter = 3'b000;
            end
            1'b0: begin
                case(sensor_state)
                    NO_LINE      : current_state = FOLLOW_LINE;
                    RIGHT_ONLY   : current_state = ADJUST_RIGHT;
                    LEFT_ONLY    : current_state = ADJUST_LEFT;
                    INTERSECTION : begin
                        current_state = FOLLOW_LINE;
                        if (intersection_counter < TASK_5)
                            intersection_counter = intersection_counter + 1;
                    end
                endcase
            end
        endcase

    // Control Signal Generation
    always @(current_state, sensor_state)
        case(sensor_state)
            INTERSECTION : begin   // At intersection
                case(intersection_counter)
                    TASK_1  : control_signals = TURN_LEFT;
                    TASK_2  : control_signals = TURN_RIGHT;
                    TASK_3  : control_signals = MOVE_FORWARD;
                    TASK_4  : control_signals = MOVE_REVERSE;
                    TASK_5  : control_signals = FULL_STOP;
                    default : control_signals = FULL_STOP;
                endcase
            end
            default : begin   // Normal line following
                case(current_state)
                    FOLLOW_LINE  : control_signals = MOVE_FORWARD;
                    ADJUST_LEFT  : control_signals = TURN_LEFT;
                    ADJUST_RIGHT : control_signals = TURN_RIGHT;
                    default     : control_signals = FULL_STOP;
                endcase
            end
        endcase
endmodule