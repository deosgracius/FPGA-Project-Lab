
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
    parameter M1_FORWARD   = 2'b01;     // Motor 1 forward (In1=0,In3=0)
    parameter M1_STOP      = 2'b11;     // against your H-bridge truth table
    parameter M1_REVERSE   = 2'b10;     
    parameter M2_FORWARD   = 2'b01;    
    parameter M2_STOP      = 2'b11;     
    parameter M2_REVERSE   = 2'b10;

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
                motor1_control = M1_STOP;
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