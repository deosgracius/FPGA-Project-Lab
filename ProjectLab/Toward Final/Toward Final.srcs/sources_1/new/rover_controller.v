module rover_controller (
    input clk,                  // Clock input
    input rst,                  // Reset input (active high)
    input [2:0] sensor_status,  // [left, right, T] from sensor_module
    input prox1,                // Proximity sensor 1 (active low)
    input done,                 // Done signal from servo_controller
    input prox2,
    input TD,
    input [1:0] HZ,
    input prox3,
    output reg [1:0] stateL,    // Left motor state
    output reg [1:0] stateR,    // Right motor state
    output reg [2:0] intersection_count, // Intersection counter
    output reg [2:0] turn_count,
    output [4:0] current_state,  // Current state for LEDs (5 bits)
    output reg THZ
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
    parameter REVERSE_LINE_FOLLOW = 5'b10101;
    parameter STOP_DELAY = 5'b10110;
    parameter TURN_IGNORE_SENSORS = 5'b10111;
    parameter FLT = 5'b11000;
    parameter Exit_pickup = 5'b11001;
    parameter LFTransmit = 5'b11010;
    parameter REVERSE_AFTER_SERVO = 5'b11011; // New state for reversing after servo

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
    reg skip_first_intersection;   // Flag to skip first intersection after tower
    reg ignore_sensors;            // Flag to ignore sensors during turn
    reg flt_to_transmit;           // Flag for FLT to LFTransmit transition
    reg ignore_all_sensors;        // Flag to ignore all sensors during turn after tower

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
            skip_first_intersection <= 0;
            ignore_sensors <= 0;
            flt_to_transmit <= 0;
            ignore_all_sensors <= 0;
        end else begin
            case (state)
                STOP: begin
                    if (to_transmit == 1) begin
                        state <= transmit;
                        to_transmit <= 0;
                    end else if (sensor_status[2:1] != 2'b00 && HZ != 2'b00) begin
                        state <= LINE_FOLLOW;
                        KHZ <= HZ;
                    end
                end
                LINE_FOLLOW: begin
                    if (pending_right_turn == 1 && sensor_status[0] == 1'b1) begin
                        state <= STOP_RIGHT;
                        pending_right_turn <= 0;
                    end else if (turn_count == 1 && ~prox1) begin
                        state <= SERVO_WAIT;
                    end else if (sensor_status[0] == 1'b1 && after_turn == 1) begin
                        state <= STOP_RIGHT;
                    end else if (sensor_status[0] == 1'b1) begin
                        state <= INTER;
                    end else if (sensor_status[2:1] == 2'b00) begin
                        state <= REVERSE;
                    end
                end
                INTER: begin
                    intersection_count <= intersection_count + 1;
                    state <= INTER_SKIP;
                end
                INTER_SKIP: begin
                    if (KHZ == 2'b01 && intersection_count == 2)
                        state <= STOP_RIGHT;
                    else if (KHZ == 2'b10 && intersection_count == 3)
                        state <= STOP_RIGHT;
                    else if (KHZ == 2'b11 && intersection_count == 4)
                        state <= STOP_RIGHT;
                    else
                        state <= CLEAR_INTERSECTION;
                end
                CLEAR_INTERSECTION: begin
                    if (Ftimer < 50_000_000)
                        Ftimer <= Ftimer + 1;
                    else begin
                        Ftimer <= 0;
                        state <= LINE_FOLLOW;
                    end
                end
                STOP_RIGHT: begin
                    if (after_tower == 1 && ignore_all_sensors == 0) begin
                        // Start the 1-second timer to ignore all sensors during turn after tower
                        ignore_all_sensors <= 1;
                        tower_turn_timer <= 0;
                    end
                    state <= INIT_TURN_RIGHT;
                end
                INIT_TURN_RIGHT: begin
                    if (after_tower == 1 && ignore_all_sensors == 1) begin
                        // Increment timer while ignoring sensors
                        if (tower_turn_timer < 100_000_000) begin // 1 second timer
                            tower_turn_timer <= tower_turn_timer + 1;
                        end else begin
                            ignore_all_sensors <= 0; // Stop ignoring sensors after 1 second
                        end
                        // Always go to adjust turn during tower sequence
                        state <= ADJUST_TURN;
                    end else if (sensor_status[2:1] == 2'b00 || ignore_all_sensors == 1) begin
                        state <= ADJUST_TURN;
                    end
                end
                ADJUST_TURN: begin
                    if (after_tower == 1 && ignore_all_sensors == 1) begin
                        // Continue incrementing timer while ignoring sensors
                        if (tower_turn_timer < 100_000_000) begin // 1 second timer
                            tower_turn_timer <= tower_turn_timer + 1;
                        end else begin
                            ignore_all_sensors <= 0; // Stop ignoring sensors after 1 second
                        end
                        
                        // Check if we need to stop ignoring sensors
                        if ((tower_turn_timer >= 100_000_000) && (sensor_status[2:1] == 2'b11)) begin
                            state <= FLT;
                            after_tower <= 0;
                            ignore_all_sensors <= 0;
                        end
                    end else if (sensor_status[2:1] == 2'b11 || ignore_all_sensors == 1) begin
                        if (flt_to_transmit == 1) begin
                            // After FLT turn sequence
                            state <= LFTransmit;
                            flt_to_transmit <= 0;
                        end else if (reverse_after_servo == 1) begin
                            // After servo sequence
                            state <= Exit_pickup;
                            reverse_after_servo <= 0;
                        end else if (after_tower == 1 && ignore_all_sensors == 0) begin
                            // After tower sequence
                            state <= FLT;
                            after_tower <= 0;
                        end else if (pending_right_turn == 1) begin
                            state <= LFTD;
                            pending_right_turn <= 0;
                        end else if (after_turn == 1) begin
                            state <= LFTD;
                            after_turn <= 2;
                        end else begin
                            state <= LINE_FOLLOW;
                            after_turn <= 1;
                            turn_count <= 1;
                        end
                    end
                end
                REVERSE: begin
                    if (sensor_status[2:1] != 2'b11)
                        state <= LINE_FOLLOW;
                end
                SERVO_WAIT: begin
                    if (~prox3) begin
                        state <= REVERSE_AFTER_SERVO;  // Change: Go to reverse first
                        servo_reverse_timer <= 0;     // Reset timer
                        ignore_sensors <= 1;          // Ignore sensor[0]
                        reverse_after_servo <= 1;     // Set flag for servo sequence
                    end
                end
                REVERSE_AFTER_SERVO: begin
                    if (servo_reverse_timer < 50_000_000) begin  // 0.5 second (50M cycles at 100MHz)
                        servo_reverse_timer <= servo_reverse_timer + 1;
                    end else begin
                        state <= STOP_LEFT;          // CHANGED: Now go to STOP_LEFT after reversing
                    end
                end
                REVERSE_LINE_FOLLOW: begin
                    if (reverse_after_servo == 1 && sensor_status[0] == 1'b1) begin
                        state <= STOP_DELAY;
                        stop_timer <= 0;
                        reverse_after_servo <= 0;
                    end else if (after_tower == 1) begin
                        if (reverse_timer < 200_000_000) begin
                            // Ignore sensors for first 2 seconds
                            reverse_timer <= reverse_timer + 1;
                        end else if (sensor_status[0] == 1'b1) begin
                            state <= STOP_DELAY;
                            stop_timer <= 0;
                            after_tower <= 0;
                            skip_first_intersection <= 0;
                        end
                    end
                end
                STOP_DELAY: begin
                    if (stop_timer < 50_000_000) begin
                        // 0.5 sec delay (50,000,000 clocks at 100MHz)
                        stop_timer <= stop_timer + 1;
                    end else begin
                        state <= TURN_IGNORE_SENSORS;
                        ignore_timer <= 0;
                        ignore_sensors <= 1;
                    end
                end
                TURN_IGNORE_SENSORS: begin
                    if (ignore_timer < 200_000_000) begin
                        // 2 sec period where sensors are ignored
                        ignore_timer <= ignore_timer + 1;
                    end else if ((sensor_status[2:1] != 2'b00) && (sensor_status[2:1] != 2'b11)) begin
                        ignore_sensors <= 0;
                        if (after_tower == 1) begin
                            // After tower path - go to FLT (changed from LFTT)
                            state <= FLT;
                        end else if (reverse_after_servo == 1) begin
                            // After servo path
                            state <= Exit_pickup;
                            reverse_after_servo <= 0;
                        end else begin
                            state <= LINE_FOLLOW;
                        end
                    end
                end
                ADJUST_AFTER_TURN: begin
                    if (sensor_status[2:1] == 2'b11)
                        state <= LINE_FOLLOW;
                end
                STOP_LEFT: begin
                    state <= INIT_TURN_LEFT;
                end
                INIT_TURN_LEFT: begin
                    if (sensor_status[2:1] != 2'b11)
                        state <= ADJUST_TURN_LEFT;
                end
                ADJUST_TURN_LEFT: begin
                    if (sensor_status[2:1] == 2'b11) begin
                        if (after_tower == 1) begin
                            state <= LINE_FOLLOW;
                            after_tower <= 0;
                            pending_right_turn <= 1;
                        end else if (turn_count == 1) begin
                            state <= LFTD;
                            after_turn <= 2;
                            turn_count <= 2;
                        end else if (turn_count == 2) begin
                            state <= delay;
                            after_turn <= 3;
                            turn_count <= 3;
                        end
                    end
                end
                LFTD: begin
                    if (~prox2) begin
                        state <= TOWER;
                    end
                end
                FLT: begin
                    // Line following after tower until sensor[0] triggers
                    if (sensor_status[0] == 1'b1) begin
                        state <= STOP_RIGHT;    // Turn right when T junction detected
                        flt_to_transmit <= 1;   // Set flag to transition to LFTransmit after turn
                    end
                end
                LFTransmit: begin
                    // Line following until prox2 triggers
                    if (~prox2) begin
                        state <= STOP;          // Stop completely when prox2 triggered
                        to_transmit <= 1;       // Set flag to trigger transmission
                    end
                end
                Exit_pickup: begin
                    // Line following until sensor[0] triggers
                    if (sensor_status[0] == 1'b1) begin
                        state <= STOP_RIGHT;    // Turn right when T junction detected
                        pending_right_turn <= 1; // Set flag to go to LFTD after turn
                    end
                end
                TOWER: begin
                    if (TD == 1) begin
                        state <= REVERSE_AFTER_TOWER;
                        Ftimer <= 0;
                        after_tower <= 1;
                    end
                end
                REVERSE_AFTER_TOWER: begin
                    if (Ftimer < 100_000_000) begin  // 1 second (100M cycles at 100MHz)
                        Ftimer <= Ftimer + 1;
                    end else begin
                        state <= STOP_LEFT;     // CHANGED: Now go to STOP_LEFT instead of STOP_RIGHT
                        ignore_sensors <= 1;     // Ignore sensor[0] during turn
                    end
                end
                delay: begin
                    if (timer2 < 100_000_000)
                        timer2 <= timer2 + 1;
                    else begin
                        timer2 <= 0;
                        state <= transmit;
                    end
                end
                transmit: begin
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
            STOP_RIGHT: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
            INIT_TURN_RIGHT: begin
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
            TURN_IGNORE_SENSORS: begin
                stateL = 2'b10;
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
            FLT: begin
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
            Exit_pickup: begin
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
            LFTransmit: begin
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
            REVERSE_LINE_FOLLOW: begin
                case (sensor_status[2:1])
                    2'b11: begin
                        stateL = 2'b01;
                        stateR = 2'b01;
                    end
                    2'b10: begin
                        stateL = 2'b01;
                        stateR = 2'b00;
                    end
                    2'b01: begin
                        stateL = 2'b00;
                        stateR = 2'b01;
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
            STOP_DELAY: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
            default: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
        endcase
    end
endmodule