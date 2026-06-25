module sensor_module(

    input sensor_left,     

    input sensor_right,    

    input sensor_T,         // T-intersection sensor (active low)

    output reg [2:0] sensor_status // [left, right, T] (active high)

);

    always @(*) begin

        sensor_status[2] = ~sensor_left;    // Convert to active high

        sensor_status[1] = ~sensor_right;

        sensor_status[0] = ~sensor_T;

    end

endmodule

module motor_control(
    input [1:0] stateL,     // Left motor: 00=Stop, 01=Forward, 10=Reverse
    input [1:0] stateR,     // Right motor
    output enA, enB,        // Motor enables
    output in1, in2, in3, in4

);
    // Enable both motors
    assign enA = 1'b1;
    assign enB = 1'b1;
    assign in1 = (stateL == 2'b01);  // Left forward
    assign in2 = (stateL == 2'b10);  // Left reverse
    assign in3 = (stateR == 2'b10);  // Right reverse
    assign in4 = (stateR == 2'b01);  // Right forward
endmodule

module servo_controller (
    input clk,
    input rst,
    input prox1,
    input prox2,
    output reg pwm_out,
    output reg servo_closed,
    output reg mosfet,
    input prox3,
    output reg done // Added as output
);
    parameter CLK_FREQ = 100_000_000;
    parameter PWM_PERIOD = 2_000_000;
    parameter OPEN_POS = 200_000;
    parameter CLOSED_POS = 70_000;

    reg [31:0] pwm_counter = 0;
    reg [31:0] target_pos = OPEN_POS;
    reg tstart = 0;
    reg [27:0] timer = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_counter <= 0;
            target_pos <= OPEN_POS;
            servo_closed <= 0;
            tstart <= 0;
            timer <= 0;
            done <= 0;
            mosfet <= 0;
            pwm_out <= 0;
        end else begin
            if (~prox1) begin
                target_pos <= CLOSED_POS;
                servo_closed <= 1;
                if (!tstart) begin
                    tstart <= 1;
                    timer <= 0;
                end
            end else if (~prox2) begin
                target_pos <= OPEN_POS;
                servo_closed <= 0;
                tstart <= 0;
                done <= 0;
            end

            if (tstart) begin
                if (timer < 200_000_000) begin
                    timer <= timer + 1;
                end else begin
                    done <= 1;
                    tstart <= 0;
                end
            end

            if (done && prox3) begin
                mosfet <= 1;
            end else begin
                mosfet <= 0;
            end

            pwm_counter <= (pwm_counter < PWM_PERIOD-1) ? pwm_counter + 1 : 0;
            pwm_out <= (pwm_counter < target_pos) ? 1'b1 : 1'b0;
        end
    end
endmodule

module rover_controller (
    input clk,                  // Clock input
    input rst,                  // Reset input (active high)
    input [2:0] sensor_status,  // [left, right, T] from sensor_module
    input prox1,                // Proximity sensor 1 (active low)
    input done,                 // Done signal from servo_controller
    output reg [1:0] stateL,    // Left motor state
    output reg [1:0] stateR,    // Right motor state
    output reg [3:0] intersection_count, // Intersection counter
    output [2:0] current_state  // Current state for LEDs
);
    // Define states using parameters
    parameter STOP = 3'b000;
    parameter LINE_FOLLOW = 3'b001;
    parameter STOP_RIGHT = 3'b010;
    parameter INIT_TURN_RIGHT = 3'b011;
    parameter ADJUST_TURN = 3'b100;
    parameter REVERSE = 3'b101;
    parameter SERVO_WAIT = 3'b110;      // New state: wait for servo actions
    parameter REVERSE_LINE_FOLLOW = 3'b111; // New state: reverse line following

    // State register
    reg [2:0] state;
    reg after_turn; // Flag to indicate post-right-turn line following

    // Assign current state to output for LEDs
    assign current_state = state;

    // Sequential logic for state transitions
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STOP;
            after_turn <= 0;
            intersection_count <= 0;
        end else begin
            case (state)
                STOP: begin
                    if (sensor_status[2:1] != 2'b00) begin
                        state <= LINE_FOLLOW;
                    end
                    after_turn <= 0;
                    // intersection_count retains its value
                end
                LINE_FOLLOW: begin
                    if (after_turn == 1 && ~prox1) begin
                        state <= SERVO_WAIT; // Prox1 triggers servo actions
                    end else if (sensor_status[0] == 1'b1) begin
                        state <= STOP_RIGHT;
                    end else if (sensor_status[2:1] == 2'b00) begin
                        state <= REVERSE;
                    end
                end
                STOP_RIGHT: begin
                    state <= INIT_TURN_RIGHT;
                end
                INIT_TURN_RIGHT: begin
                    state <= ADJUST_TURN;
                end
                ADJUST_TURN: begin
                    if (sensor_status[2:1] == 2'b11) begin
                        state <= LINE_FOLLOW;
                        after_turn <= 1; // Set flag after right turn
                        intersection_count <= intersection_count + 1; // Increment counter
                    end
                end
                REVERSE: begin
                    if (sensor_status[2:1] != 2'b00) begin
                        state <= LINE_FOLLOW;
                    end
                end
                SERVO_WAIT: begin
                    if (done) begin
                        state <= REVERSE_LINE_FOLLOW; // Servo done, start reverse
                    end
                end
                REVERSE_LINE_FOLLOW: begin
                    if (sensor_status[0] == 1'b1) begin
                        state <= STOP; // Stop at intersection
                    end
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
                        stateL = 2'b10;  // Forward (corrected)
                        stateR = 2'b10;
                    end
                    2'b10: begin
                        stateL = 2'b10;  // Forward
                        stateR = 2'b00;  // Stop (turn right)
                    end
                    2'b01: begin
                        stateL = 2'b00;  // Stop
                        stateR = 2'b10;  // Forward (turn left)
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
                stateL = 2'b10;  // Forward
                stateR = 2'b01;  // Reverse (sharp right turn)
            end
            ADJUST_TURN: begin
                case (sensor_status[2:1])
                    2'b00: begin
                        stateL = 2'b01;  // Forward
                        stateR = 2'b10;  // Reverse
                    end
                    2'b10: begin
                        stateL = 2'b10;  // Forward
                        stateR = 2'b00;  // Stop
                    end
                    2'b01: begin
                        stateL = 2'b00;  // Stop
                        stateR = 2'b10;  // Forward
                    end
                    2'b11: begin
                        stateL = 2'b10;  // Forward
                        stateR = 2'b10;  // Forward
                    end
                endcase
            end
            REVERSE: begin
                stateL = 2'b01;  // Reverse (corrected)
                stateR = 2'b01;
            end
            SERVO_WAIT: begin
                stateL = 2'b00;  // Stop while servo acts
                stateR = 2'b00;
            end
            REVERSE_LINE_FOLLOW: begin
                case (sensor_status[2:1])
                    2'b11: begin
                        stateL = 2'b01;  // Reverse
                        stateR = 2'b01;
                    end
                    2'b10: begin
                        stateL = 2'b01;  // Stop
                        stateR = 2'b00;  // Reverse (turn left)
                    end
                    2'b01: begin
                        stateL = 2'b00;  // Reverse
                        stateR = 2'b01;  // Stop (turn right)
                    end
                    2'b00: begin
                        stateL = 2'b10;  // Reverse
                        stateR = 2'b10;
                    end
                endcase
            end
        endcase
    end
endmodule

module top (
    input clk,           // 100 MHz clock
    //input rst,           // Reset (active high)
    input sensor_left,   // Left sensor (active low)
    input sensor_right,  // Right sensor (active low)
    input sensor_T,      // T-sensor (active low)
    input prox1,         // Proximity sensor 1 (active low)
    input prox2,         // Proximity sensor 2 (active low)
    input prox3,  // Limit switch
    output enA,          // Left motor enable
    output enB,          // Right motor enable
    output in1,          // Left motor forward
    output in2,          // Left motor reverse
    output in3,          // Right motor reverse
    output in4,          // Right motor forward
    output pwm_servo,    // Servo PWM
    output mosfet,       // MOSFET control
    output [15:0] led,   // LEDs on Basys 3
    output [6:0] seg,    // Seven-segment segments
    output [3:0] an      // Seven-segment anodes
);
    // Internal wires
    wire [2:0] sensor_status;
    wire [1:0] stateL, stateR;
    wire [3:0] intersection_count;
    wire [2:0] current_state;
    wire done;

    // Instantiate sensor_module
    sensor_module sensors (
        .sensor_left(sensor_left),
        .sensor_right(sensor_right),
        .sensor_T(sensor_T),
        .sensor_status(sensor_status)
    );

    // Instantiate rover_controller
    rover_controller controller (
        .clk(clk),
        //.rst(rst),
        .sensor_status(sensor_status),
        .prox1(prox1),
        .done(done),
        .stateL(stateL),
        .stateR(stateR),
        .intersection_count(intersection_count),
        .current_state(current_state)
    );

    // Instantiate motor_control
    motor_control motors (
        .stateL(stateL),
        .stateR(stateR),
        .enA(enA),
        .enB(enB),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .in4(in4)
    );

    // Instantiate servo_controller
    servo_controller servo (
        .clk(clk),
        //.rst(rst),
        .prox1(prox1),
        .prox2(prox2),
        .pwm_out(pwm_servo),
        .servo_closed(), // Not connected
        .mosfet(mosfet),
        .prox3(prox3),
        .done(done)
    );

    // Instantiate seven_seg_decoder
    seven_seg_decoder decoder (
        .digit(intersection_count),
        .seg(seg)
    );

    // Assign outputs
    assign an = 4'b1110;          // Enable rightmost digit
    assign led[2:0] = current_state; // Show state on LEDs 2:0
    assign led[15:3] = 13'b0;     // Turn off unused LEDs
endmodule


## Clock signal
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# Motor control and Servo (JXADC)
set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports pwm_servo]
set_property -dict { PACKAGE_PIN L3   IOSTANDARD LVCMOS33 } [get_ports enB]
set_property -dict { PACKAGE_PIN M2   IOSTANDARD LVCMOS33 } [get_ports in4]
set_property -dict { PACKAGE_PIN N2   IOSTANDARD LVCMOS33 } [get_ports in2]
set_property -dict { PACKAGE_PIN K3   IOSTANDARD LVCMOS33 } [get_ports enA]
set_property -dict { PACKAGE_PIN M1   IOSTANDARD LVCMOS33 } [get_ports in3]
set_property -dict { PACKAGE_PIN N1   IOSTANDARD LVCMOS33 } [get_ports in1]

## IPS Sensors, Proximity sensors and MOSFET (JC)
set_property -dict { PACKAGE_PIN K17  IOSTANDARD LVCMOS33 } [get_ports prox1]
set_property -dict { PACKAGE_PIN M18  IOSTANDARD LVCMOS33 } [get_ports sensor_T]
set_property -dict { PACKAGE_PIN N17  IOSTANDARD LVCMOS33 } [get_ports sensor_right]
set_property -dict { PACKAGE_PIN P18  IOSTANDARD LVCMOS33 } [get_ports sensor_left]
set_property -dict { PACKAGE_PIN L17  IOSTANDARD LVCMOS33 } [get_ports mosfet]
set_property -dict { PACKAGE_PIN M19  IOSTANDARD LVCMOS33 } [get_ports prox3]
set_property -dict { PACKAGE_PIN P17  IOSTANDARD LVCMOS33 } [get_ports prox2]


## LEDs
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports {led[7]}]
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports {led[8]}]
set_property -dict { PACKAGE_PIN V3    IOSTANDARD LVCMOS33 } [get_ports {led[9]}]
set_property -dict { PACKAGE_PIN W3    IOSTANDARD LVCMOS33 } [get_ports {led[10]}]
set_property -dict { PACKAGE_PIN U3    IOSTANDARD LVCMOS33 } [get_ports {led[11]}]
set_property -dict { PACKAGE_PIN P3    IOSTANDARD LVCMOS33 } [get_ports {led[12]}]
set_property -dict { PACKAGE_PIN N3    IOSTANDARD LVCMOS33 } [get_ports {led[13]}]
set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 } [get_ports {led[14]}]
set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports {led[15]}]


## Seven Segment Display
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]
set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]    


set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {an[0]}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {an[3]}]