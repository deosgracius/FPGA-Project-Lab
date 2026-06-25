module rover_controller (
    input clk,                  // Clock input
    input rst,                  // Reset input (active high)
    input [3:0] sensor_status,  // [left, right, T] from sensor_module
    input prox1,                // Proximity sensor 1 (active low)
    input done,                 // Done signal from servo_controller
    input prox2,
    input TD,
    input [1:0] HZ,
    input prox3,
    output reg servo_mosfet,
    output reg [1:0] stateL,    // Left motor state
    output reg [1:0] stateR,    // Right motor state
    output reg [2:0] intersection_count, // Intersection counter
    output reg [2:0] turn_count,
    output [4:0] current_state,  // Current state for LEDs (5 bits)
    output reg THZ,
    output reg servo_start,
    output reg servo_on
);
    // Define states using parameters
    parameter STOP = 5'b00000;
    parameter LINE_FOLLOW = 5'b00001;
    parameter STOP_RIGHT = 5'b00010;
    parameter INIT_TURN_RIGHT = 5'b00011;
    parameter ADJUST_TURN = 5'b00100;
    parameter REVERSE = 5'b00101;
    parameter SERVO_WAIT = 5'b00110;
    // Removed TURN_LEFT
    parameter ADJUST_AFTER_TURN = 5'b01000;
    parameter STOP_LEFT = 5'b01001;
    parameter INIT_TURN_LEFT = 5'b01010;
    parameter ADJUST_TURN_LEFT = 5'b01011;
    parameter INTER_SKIP = 5'b01100;
    parameter TOWER = 5'b01101;
    parameter delay = 5'b01110;
    parameter transmit = 5'b01111;
    parameter INTER = 5'b10000;
    parameter CLEAR_INTERSECTION = 5'b10001;
    parameter LFTD = 5'b10010;
    // Removed FOLLOW_LINE_1SEC
    parameter REVERSE_AFTER_TOWER = 5'b10100;
    parameter REVERSE_AFTER_SERVO = 5'b11011; // New state for reversing after servo
    parameter forward_delay = 5'b11100;
    parameter init_forward = 5'b11101;
    parameter INIT_TURN_2 = 5'b11110;
    parameter after_block_left = 5'b11111;

    // State register and other registers
    reg [4:0] state;
    reg after_turn;
    reg AB;
    reg [27:0] timer2;
    reg skip;
    reg [27:0] Ftimer;
    reg [1:0] Example = 2'b01;
    reg [1:0] KHZ;
    reg [27:0] turn_timer;         // Timer for turn duration
    reg [27:0] stop_timer;         // Timer for 0.5 sec stop
    reg [27:0] ignore_timer;       // Timer for 2-sec sensor ignore
    reg [27:0] reverse_timer;      // Timer for 2-sec minimum reverse
    reg [27:0] servo_reverse_timer; // Timer for 0.5 sec after servo reverse
    reg [27:0] tower_turn_timer;   // Timer for 1 sec sensor ignore during turn after tower
    reg after_tower;               // Flag for post-TOWER sequence
    reg pending_right_turn;        // Flag for right turn after left
    reg to_transmit;               // Flag to trigger transmit
    reg reverse_after_servo;       // Flag for post-SERVO sequence
    reg ignore_sensors;            // Flag to ignore sensors during turn
    reg ignore_all_sensors;        // Flag to ignore all sensors during turn after tower
    reg [27:0] back_delay;
    reg disable_pwm;               // Flag to disable PWM to reduce current draw
    reg [27:0] fdelay;

    // Assign current state to output for LEDs
    assign current_state = state;
        
    // Sequential logic for state transitions
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STOP;
            after_turn <= 0;
            intersection_count <= 0;
            turn_count <= 0;
            AB <= 0;
            timer2 <= 0;
            skip <= 0;
            Ftimer <= 0;
            Example <= 0;
            KHZ <= 0;
            turn_timer <= 0;
            stop_timer <= 0;
            ignore_timer <= 0;
            reverse_timer <= 0;
            servo_reverse_timer <= 0;
            tower_turn_timer <= 0;
            after_tower <= 0;
            pending_right_turn <= 0;
            to_transmit <= 0;
            reverse_after_servo <= 0;
            ignore_sensors <= 0;
            ignore_all_sensors <= 0;
            servo_on <= 0;
            servo_start <= 0;
            back_delay <= 0;
            disable_pwm <= 0;
            servo_mosfet <= 0;
            fdelay <= 0;
        end else begin
            case (state)
                STOP: begin
                    if (to_transmit == 1) begin
                        state <= transmit;
                        to_transmit <= 0;
                    end else if (HZ != 2'b00 && turn_count == 0) begin          //begin when servo recieves ir signal
                        state <= init_forward;
                    end
                end
                init_forward: begin
                    if (sensor_status[2:1] == 2'b11) begin
                        state <= LINE_FOLLOW;
                    end
                end
                LINE_FOLLOW: begin
                    // NEW: Check for prox2 after final right turn to immediately stop and transmit
                    if (turn_count == 3 && ~prox2) begin                                    // After final turn when prox2 triggers
                        to_transmit <= 1;
                        state <= STOP;
                    end else if (pending_right_turn == 1 && sensor_status[0] == 1'b1) begin // Final right turn to transmit
                        state <= forward_delay;
                        pending_right_turn <= 0;
                        fdelay <= 0;
                    end else if (turn_count == 2 && sensor_status[0] == 1'b1) begin         // Second right turn to tower
                        state <= forward_delay;
                        fdelay <= 0;
                    end else if (turn_count == 1 && ~prox1 && ignore_all_sensors == 0) begin// After first right turn to servo
                        state <= SERVO_WAIT;
                        servo_start <= 1;  // Activate servo_start when prox1 triggers
                    end else if (sensor_status[0] == 1'b1 && turn_count == 0) begin         // First right turn to servo
                        state <= INTER;
                    end else if (sensor_status[2:1] == 2'b00) begin                         // If no sensor detects then reverse
                        state <= REVERSE;
                    end
                end
                INTER: begin                                                                // Increment intersection count every time entered
                    intersection_count <= intersection_count + 1;
                    state <= INTER_SKIP;
                end
                INTER_SKIP: begin                                                           // Skip intersections relating to signal
                    if (HZ == 2'b01 && intersection_count == 2) begin
                        state <= forward_delay;
                        fdelay <= 0;
                    end else if (HZ == 2'b10 && intersection_count == 3) begin
                        state <= forward_delay;
                        fdelay <= 0;
                    end else if (HZ == 2'b11 && intersection_count == 4) begin
                        state <= forward_delay;
                        fdelay <= 0;
                    end else begin
                        state <= CLEAR_INTERSECTION;
                    end
                end
                CLEAR_INTERSECTION: begin                                                   // For the skipped intersections dont let intersection sensor go off again for 500ms
                    if (Ftimer < 150_000_000) begin
                        Ftimer <= Ftimer + 1;
                    end else begin
                        Ftimer <= 0;
                        state <= LINE_FOLLOW;
                    end
                end
                forward_delay: begin
                    if (sensor_status[0] == 1'b0) begin
                        state <= STOP_RIGHT;
                        fdelay <= 0;
                    end
                end
                STOP_RIGHT: begin 
                    if (fdelay == 50_000_000) begin                                             // Stop after right turn
                        if (after_tower == 1 && ignore_all_sensors == 0) begin
                            // Start the 1-second timer to ignore all sensors during turn after tower
                            ignore_all_sensors <= 1;
                        end
                        state <= INIT_TURN_RIGHT;
                    end else begin
                        fdelay <= fdelay + 1;
                    end
                end
                INIT_TURN_RIGHT: begin                                                      // Start turning right until both sensors dont detect the line
                    // Modified: If this is after the servo completion (turn_count == 2) and one sensor triggers, go to LFTD
                    if (turn_count == 2 && (sensor_status[2] == 1'b1 || sensor_status[1] == 1'b1)) begin
                        state <= LFTD;
                        reverse_after_servo <= 0;
                    end else if (sensor_status[1] == 1'b0) begin
                        state <= INIT_TURN_2;
                    end
                end
                INIT_TURN_2: begin
                    // Modified: If this is after the servo completion (turn_count == 2) and one sensor triggers, go to LFTD
                    if (turn_count == 2 && (sensor_status[2] == 1'b1 || sensor_status[1] == 1'b1)) begin
                        state <= LFTD;
                        reverse_after_servo <= 0;
                    end else if (sensor_status[2] == 1'b0) begin
                        state <= ADJUST_TURN;
                    end 
                end
                ADJUST_TURN: begin                                                          // Keep turning until the both front sensors detect line
                    // Modified: If this is after the servo completion (turn_count == 2) and one sensor triggers, go to LFTD
                    if (turn_count == 2 && (sensor_status[2] == 1'b1 || sensor_status[1] == 1'b1)) begin
                        state <= LFTD;
                        reverse_after_servo <= 0;
                    end else if (after_tower == 1 && ignore_all_sensors == 1) begin                  // Final right turn to transmit tower
                        if (sensor_status[2:1] == 2'b11) begin
                            pending_right_turn <= 0;
                            turn_count <= 3;  // CHANGED: Set to 3 instead of 4 to match your requirement 3
                            after_turn <= 3;
                            ignore_all_sensors <= 0;
                            state <= LINE_FOLLOW;
                        end
                    end else if (sensor_status[2:1] == 2'b11 || ignore_all_sensors == 1) begin
                        if (reverse_after_servo == 1) begin                                 // Second right turn to tower
                            // After servo sequence
                            state <= LFTD;
                            reverse_after_servo <= 0;
                        end else if (after_tower <= 0) begin                                                      // First right turn to servo
                            state <= LINE_FOLLOW;
                            after_turn <= 1;
                            turn_count <= 1;
                            servo_on <= 1;  // Set servo_on after right turn
                            servo_mosfet <= 1;
                        end
                    end
                end
                REVERSE: begin
                    if (sensor_status[2:1] == 2'b11)
                        state <= LINE_FOLLOW;
                end
                SERVO_WAIT: begin                                                           // When the proximity sensor detects block then close claw and stop rover until claw is at top
                    if (~prox3) begin
                        state <= STOP_LEFT;  // Change: Go to reverse first
                        servo_reverse_timer <= 0;      // Reset timer
                        ignore_sensors <= 1;           // Ignore sensor[0]
                        reverse_after_servo <= 1;      // Set flag for servo sequence
                        servo_on <= 0;                 // Turn off servo_on (UNCHANGED)
                        disable_pwm <= 1;              // UNCHANGED: Disable PWM to reduce current draw
                        servo_mosfet <= 0;
                    end
                end
                REVERSE_AFTER_SERVO: begin                                                  // Reverse for 500 ms after picking up block
                    if (servo_reverse_timer < 50_000_000) begin  // 0.5 second (50M cycles at 100MHz)
                        servo_reverse_timer <= servo_reverse_timer + 1;
                    end else begin
                        state <= STOP_LEFT;          // CHANGED: Now go to STOP_LEFT after reversing
                    end
                end
                STOP_LEFT: begin
                    state <= INIT_TURN_LEFT;
                end
                INIT_TURN_LEFT: begin
                    if (sensor_status[2:1] == 2'b00)
                        state <= ADJUST_TURN_LEFT;
                end
                ADJUST_TURN_LEFT: begin                                                     // Turn around
                    if (sensor_status[2:1] == 2'b11) begin
                        if (after_tower == 1) begin                                         // Turn around after tower
                            state <= LINE_FOLLOW;
                            pending_right_turn <= 1;                                        // Flag to make right turn at next intersection
                            turn_count <= 3;                                                // CHANGED: Set to 3 to match your requirement 3
                            after_turn <= 3;
                        end else if (turn_count == 1) begin                                 // Turn around after servo
                            state <= after_block_left;
                            after_turn <= 2;
                            turn_count <= 2;
                        end
                    end
                end
                after_block_left: begin
                    if (sensor_status[0] == 1'b1) begin
                        state <= forward_delay;
                    end
                end
                LFTD: begin                                                                 // Go forward without taking intersection sensor into account to tower
                    // MODIFICATION: For requirement 2, check prox2 regardless of prox1 state
                    if (~prox2) begin  // If prox2 is triggered (active low)
                        state <= TOWER;
                        back_delay <= 0;
                        servo_mosfet <= 1;
                    end
                end
                TOWER: begin                                                                // After 1 second delay after dropping the block and turning pwm off go to reverse after tower
                    if (TD == 1 && back_delay == 100_000_000) begin
                        state <= REVERSE_AFTER_TOWER;
                        Ftimer <= 0;
                        after_tower <= 1;
                        servo_start <= 0;
                        disable_pwm <= 1; 
                        servo_mosfet <= 0;                                                  // Disable PWM to reduce current draw
                    end else begin
                        back_delay <= back_delay + 1;
                    end
                end
                REVERSE_AFTER_TOWER: begin
                    if (Ftimer < 50_000_000) begin  // 1 second (100M cycles at 100MHz)
                        Ftimer <= Ftimer + 1;
                    end else begin
                        state <= STOP_LEFT;           // CHANGED: Now go to STOP_LEFT instead of STOP_RIGHT
                        ignore_sensors <= 1;          // Ignore sensor[0] during turn
                    end
                end
                transmit: begin                                                             // Saturday-Sunday thing
                    THZ <= 1;
                end
            endcase
        end
    end

    // Combinational logic for motor outputs
    always @(*) begin
        case (state)
            STOP: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
            init_forward: begin
                stateL = 2'b10;
                stateR = 2'b10;
            end
            LINE_FOLLOW: begin
                case (sensor_status[2:1])
                    2'b11: begin
                        stateL = 2'b10;
                        stateR = 2'b10;
                    end
                    2'b10: begin
                        stateL = 2'b10;
                        stateR = 2'b00;
                    end
                    2'b01: begin
                        stateL = 2'b00;
                        stateR = 2'b10;
                    end
                    2'b00: begin
                        stateL = 2'b01;
                        stateR = 2'b01;
                    end
                    default: begin
                        stateL = 2'b00;
                        stateR = 2'b00;
                    end
                endcase
            end
            after_block_left: begin
                case (sensor_status[2:1])
                    2'b11: begin
                        stateL = 2'b10;
                        stateR = 2'b10;
                    end
                    2'b10: begin
                        stateL = 2'b10;
                        stateR = 2'b00;
                    end
                    2'b01: begin
                        stateL = 2'b00;
                        stateR = 2'b10;
                    end
                    2'b00: begin
                        stateL = 2'b10;
                        stateR = 2'b10;
                    end
                    default: begin
                        stateL = 2'b00;
                        stateR = 2'b00;
                    end
                endcase
            end
            STOP_RIGHT: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
            INIT_TURN_RIGHT: begin
                stateL = 2'b01;
                stateR = 2'b10;
            end
            INIT_TURN_2: begin
                stateL = 2'b01;
                stateR = 2'b10;
            end
            ADJUST_TURN: begin
                case (sensor_status[2:1])
                    2'b00: begin
                        stateL = 2'b01;
                        stateR = 2'b10;
                    end
                    2'b10: begin
                        stateL = 2'b10;
                        stateR = 2'b00;
                    end
                    2'b01: begin
                        stateL = 2'b00;
                        stateR = 2'b10;
                    end
                    2'b11: begin
                        stateL = 2'b10;
                        stateR = 2'b10;
                    end
                    default: begin
                        stateL = 2'b00;
                        stateR = 2'b00;
                    end
                endcase
            end
            REVERSE: begin
                stateL = 2'b01;
                stateR = 2'b01;
            end
            SERVO_WAIT: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
            REVERSE_AFTER_SERVO: begin
                stateL = 2'b01;
                stateR = 2'b01;
            end
            ADJUST_AFTER_TURN: begin
                case (sensor_status[2:1])
                    2'b11: begin
                        stateL = 2'b10;
                        stateR = 2'b10;
                    end
                    2'b10: begin
                        stateL = 2'b10;
                        stateR = 2'b00;
                    end
                    2'b01: begin
                        stateL = 2'b00;
                        stateR = 2'b10;
                    end
                    2'b00: begin
                        stateL = 2'b01;
                        stateR = 2'b01;
                    end
                    default: begin
                        stateL = 2'b00;
                        stateR = 2'b00;
                    end
                endcase
            end
            STOP_LEFT: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
            INIT_TURN_LEFT: begin
                stateL = 2'b10;
                stateR = 2'b01;
            end
            ADJUST_TURN_LEFT: begin
                case (sensor_status[2:1])
                    2'b00: begin
                        stateL = 2'b10;
                        stateR = 2'b01;
                    end
                    2'b10: begin
                        stateL = 2'b10;
                        stateR = 2'b00;
                    end
                    2'b01: begin
                        stateL = 2'b00;
                        stateR = 2'b10;
                    end
                    2'b11: begin
                        stateL = 2'b10;
                        stateR = 2'b10;
                    end
                    default: begin
                        stateL = 2'b00;
                        stateR = 2'b00;
                    end
                endcase
            end
            INTER_SKIP: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
            TOWER: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
            transmit: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
            CLEAR_INTERSECTION: begin
                stateL = 2'b10;
                stateR = 2'b10;
            end
            LFTD: begin
                case (sensor_status[2:1])
                    2'b11: begin
                        stateL = 2'b10;
                        stateR = 2'b10;
                    end
                    2'b10: begin
                        stateL = 2'b10;
                        stateR = 2'b00;
                    end
                    2'b01: begin
                        stateL = 2'b00;
                        stateR = 2'b10;
                    end
                    2'b00: begin
                        stateL = 2'b01;
                        stateR = 2'b01;
                    end
                    default: begin
                        stateL = 2'b00;
                        stateR = 2'b00;
                    end
                endcase
            end
            REVERSE_AFTER_TOWER: begin
                stateL = 2'b01;
                stateR = 2'b01;
            end
            default: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
            forward_delay: begin
                stateL = 2'b10;
                stateR = 2'b10;
            end
        endcase
    end
endmodule