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
    output [4:0] current_state,  // Current state for LEDs (4 bits)
    output reg THZ
);
    // Define states using parameters
    parameter STOP = 5'b00000;
    parameter LINE_FOLLOW = 5'b00001;
    parameter STOP_RIGHT = 5'b00010;
    parameter INIT_TURN_RIGHT = 5'b00011;
    parameter ADJUST_TURN = 5'b00100;
    parameter REVERSE = 5'b00101;
    parameter SERVO_WAIT = 5'b00110;      // New state: wait for servo actions
    parameter REVERSE_LINE_FOLLOW = 5'b00111; // New state: reverse line following
    parameter STOP_LEFT = 5'b01000;
    parameter INIT_TURN_LEFT = 5'b01001;
    parameter ADJUST_TURN_LEFT = 5'b01010;
    parameter INTER_SKIP = 5'b01011;
    parameter TOWER = 5'b01100;
    parameter delay = 5'b01101;
    parameter transmit = 5'b01110;
    parameter INTER = 5'b01111;
    parameter CLEAR_INTERSECTION = 5'b10000;
    parameter LFTD = 5'b10001;

    // State register (4 bits to hold 4-bit state constants)
    reg [4:0] state;
    reg after_turn; // Flag to indicate post-turn actions
    reg AB;
    reg [27:0] timer2;
    reg skip;
    reg [27:0] Ftimer;
    reg [1:0] Example = 2'b01;
    reg [1:0] KHZ;

    // Assign current state to output for LEDs
    assign current_state = state;
        
    // Sequential logic for state transitions
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STOP;
            after_turn <= 0;
            intersection_count <= 0;
            turn_count <= 0;     // Initialize turn_count on reset
            AB <= 0;
            timer2 <= 0;
            skip <= 0;
            Ftimer <= 0;
            Example <= 0;
            KHZ <= 0;
        end else begin
            case (state)
                STOP: begin
                    if (sensor_status[2:1] != 2'b00 && HZ != 2'b00)
                        state <= LINE_FOLLOW;
                        KHZ = HZ;
                end
                LINE_FOLLOW: begin
                    if (turn_count == 1 && ~prox1)
                        state <= SERVO_WAIT; // Prox1 triggers servo actions
                    else if (sensor_status[0] == 1'b1)
                        state <= INTER;
                    else if (sensor_status[2:1] == 2'b00)
                        state <= REVERSE;
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
                // Continue driving forward until the timer expires
                if (Ftimer < 50_000_000)
                    Ftimer <= Ftimer + 1;
                else begin
                    Ftimer <= 0;
                    state <= LINE_FOLLOW; // Return to normal line following after 500ms
                end
            end
                STOP_RIGHT: begin
                    state <= INIT_TURN_RIGHT;
                end
                INIT_TURN_RIGHT: begin
                    if (sensor_status[2:1] == 2'b00)
                        state <= ADJUST_TURN;
                end
                ADJUST_TURN: begin
                    // Removed sequential motor output assignments for stateL and stateR here.
                    if (sensor_status[2:1] == 2'b11) begin
                        state <= LINE_FOLLOW;
                        after_turn <= 1; // Set flag after turn
                        turn_count <= 1; // Initialize turn_count to 1
                    end
                end
                REVERSE: begin
                    if (sensor_status[2:1] != 2'b11)
                        state <= LINE_FOLLOW;
                end
                SERVO_WAIT: begin
                    if (~prox3) begin
                        AB <= 1;
                        state <= REVERSE_LINE_FOLLOW; // Servo done, start reverse
                    end
                end
                REVERSE_LINE_FOLLOW: begin
                    if (sensor_status[0] == 1'b1 && AB == 1) begin
                        AB <= 0;
                        state <= STOP_LEFT; // Stop at intersection
                    end else if (TD == 1) begin
                        if (sensor_status[0] == 1'b1 && skip == 0) begin
                            skip <= 1;
                            state <= REVERSE_LINE_FOLLOW;
                        end else if (skip == 1) begin
                            state <= STOP_LEFT;
                        end
                    end
                end 
                STOP_LEFT: begin
                    state <= INIT_TURN_LEFT;
                end
                INIT_TURN_LEFT: begin
                    if (sensor_status[2:1] != 2'b11)
                        state <= ADJUST_TURN_LEFT;
                end
                ADJUST_TURN_LEFT: begin
                    // Removed sequential motor output assignments for stateL and stateR here.
                    if (sensor_status[2:1] == 2'b11 && turn_count == 1) begin
                        state <= LFTD;
                        after_turn <= 2; // Set flag after turn
                        turn_count <= 2; // Increment counter
                    end else if (sensor_status[2:1] == 2'b11 && turn_count == 2) begin
                        state <= delay;
                        after_turn <= 3; // Set flag after turn
                        turn_count <= 3; // Increment counter
                    end
                end
                LFTD: begin
                    if (~prox2)
                        state <= TOWER;
                end
                TOWER: begin    
                    if (TD == 1)
                        state <= REVERSE_LINE_FOLLOW;
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
                stateL = 2'b00;  // Stop
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
            default: begin
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
        endcase
    end
endmodule