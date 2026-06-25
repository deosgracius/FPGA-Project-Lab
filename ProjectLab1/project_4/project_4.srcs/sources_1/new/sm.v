
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/30/2025 12:29:00 AM
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


// State Machine Module with encoded states and tasks
module state_machine(
    input clck,                             // System clock
    input rst,                              // Reset signal
    input wire [1:0] sensor_state,          // Input from sensor module
    output reg [3:0] control_signals,       // Output to motor control
    output reg [2:0] intersection_counter   // Intersection counter
);
    // State Machine State Encodings
    parameter FOLLOW_LINE   = 3'b001;       // Normal line following
    parameter ADJUST_LEFT   = 3'b010;       // Correcting to the left
    parameter ADJUST_RIGHT  = 3'b100;       // Correcting to the right

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
    parameter TASK_1       = 3'b000;        // First intersection: Turn left
    parameter TASK_2       = 3'b001;        // Second intersection: Turn right
    parameter TASK_3       = 3'b010;        // Third intersection: Forward
    parameter TASK_4       = 3'b011;        // Fourth intersection: Reverse
    parameter TASK_5       = 3'b100;        // Fifth intersection: Stop
   
    reg [2:0] current_state;

    // State Machine Logic
    always @(posedge clck)
        case(rst)
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
