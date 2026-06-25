`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2025 08:33:26 PM
// Design Name: 
// Module Name: Rover_Controller_m
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Rover controller for line following with right turn at T-intersection
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
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
        end else begin
            case (state)
                STOP: begin
                    if (sensor_status[2:1] != 2'b00 && HZ != 2'b00)
                        state <= LINE_FOLLOW;
                    after_turn <= 0;
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
                    if (HZ == 2'b01 && intersection_count == 2)
                        state <= STOP_RIGHT;
                    else if (HZ == 2'b10 && intersection_count == 3)
                        state <= STOP_RIGHT;
                    else if (HZ == 2'b11 && intersection_count == 4)
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
                    if (sensor_status[2:1] != 2'b11)
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
                stateL = 2'b00;  
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
                stateR = 2'b00;
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
    output reg done, // Added as output
    output reg TD
);
    parameter CLK_FREQ = 100_000_000;
    parameter PWM_PERIOD = 2_000_000;
    parameter OPEN_POS = 200_000;
    parameter CLOSED_POS = 70_000;

    reg [31:0] pwm_counter = 0;
    reg [31:0] target_pos = OPEN_POS;
    reg tstart = 0;
    reg [27:0] timer = 0;
    reg [27:0] timer1 = 0;
    reg TS = 0;

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
            timer1 <= 0;
            TD <= 0;
            TS <= 0;
        end else begin
            if (~prox1) begin
                target_pos <= CLOSED_POS;
                servo_closed <= 1;
                if (!tstart) begin
                    tstart <= 1;
                    timer <= 0;
                end
            end else if (~prox2 && ~prox3) begin
                TS = 1;
                target_pos <= OPEN_POS;
                servo_closed <= 0;
            end
            
            if (TS == 1) begin
                if (timer1 < 100_000_000) begin
                    timer1 <= timer1 + 1;
                end else begin
                    TD <= 1;
                    target_pos <= OPEN_POS;
                    servo_closed <= 0;
                end
            end
            
            if (tstart) begin
                if (timer < 200_000_000) begin
                    timer <= timer + 1;
                end else begin
                    done <= 1;
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

module seven_seg_decoder (
    input [3:0] digit,
    output reg [6:0] seg
);
    always @(*) begin
        case (digit)
            4'd0: seg = 7'b0000001; // a-f on, g off
            4'd1: seg = 7'b1001111; // b, c on
            4'd2: seg = 7'b0010010;
            4'd3: seg = 7'b0000110;
            4'd4: seg = 7'b1001100;
            4'd5: seg = 7'b0100100;
            4'd6: seg = 7'b0100000;
            4'd7: seg = 7'b0001111;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0000100;
            default: seg = 7'b1111111; // Off
        endcase
    end
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
set_property -dict { PACKAGE_PIN M3   IOSTANDARD LVCMOS33 } [get_ports ir_input];
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


module top (
    input clk,           // 100 MHz clock
    //input rst,         // Reset (active high) - tied to a constant in this design
    input sensor_left,   // Left sensor (active low)
    input sensor_right,  // Right sensor (active low)
    input sensor_T,      // T-sensor (active low)
    input prox1,         // Proximity sensor 1 (active low)
    input prox2,         // Proximity sensor 2 (active low)
    input prox3,         // Limit switch
    input ir_input,      //IR reciever
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

    // Tie reset to a constant low (inactive)
    wire rst = 1'b0;
    wire [1:0] HZ;

    // Internal wires
    wire [2:0] sensor_status;
    wire [1:0] stateL, stateR;
    wire [2:0] intersection_count;
    wire [4:0] current_state;
    wire done;
    wire [2:0] turn_count;  // Added dummy connection for rover turn_count
    wire servo_TD;          // Wire to carry servo TD signal

    // Instantiate sensor_module
    sensor_module sensors (
        .sensor_left(sensor_left),
        .sensor_right(sensor_right),
        .sensor_T(sensor_T),
        .sensor_status(sensor_status)
    );

    // Instantiate rover_controller (now connecting missing ports)
    rover_controller controller (
        .clk(clk),
        .rst(rst),
        .sensor_status(sensor_status),
        .prox1(prox1),
        .done(done),
        .prox2(prox2),
        .TD(servo_TD),
        .stateL(stateL),
        .stateR(stateR),
        .intersection_count(intersection_count),
        .turn_count(turn_count),
        .current_state(current_state),
        .THZ(),  // THZ output left unconnected if not used
        .HZ(HZ),
        .prox3(prox3)
);

    // Instantiate motor_control (changed below to remove extra comma)
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

    // Instantiate servo_controller (now connecting reset and TD)
    servo_controller servo (
        .clk(clk),
        .rst(rst),
        .prox1(prox1),
        .prox2(prox2),
        .pwm_out(pwm_servo),
        .servo_closed(), // Not connected
        .mosfet(mosfet),
        .prox3(prox3),
        .done(done),
        .TD(servo_TD)
    );

    // Instantiate seven_seg_decoder
    seven_seg_decoder decoder (
        .digit(intersection_count),
        .seg(seg)
    );
    
    // Instantiate the IR receiver module
    ir_receiver ir_rec_instance (
        .clk(clk),
        .ir_input(ir_input),
        .HZ(HZ)
    );

    assign led[0] = (HZ == 2'b00);  // LED[0] on for 1 kHz
    assign led[1] = (HZ == 2'b01);  // LED[1] on for 2 kHz
    assign led[2] = (HZ == 2'b10);  // LED[2] on for 3 kHz
    assign led[3] = (HZ == 2'b11);  // LED[3] on for invalid
    assign led[15:4] = 12'b0;             // Keep remaining LEDs off

endmodule

module ir_receiver (
    input clk,          // 100 MHz clock
    input ir_signal,     // IR sensor input
    output reg [1:0] HZ  // 00=1kHz, 01=2kHz, 10=3kHz, 11=invalid
);

    // Synchronize the IR input to avoid metastability
    reg [1:0] ir_sync;
    reg ir_prev;
    reg HZFLAG;
    reg disable1 = 0;
    always @(posedge clk) begin
        ir_sync <= {ir_sync[0], ir_signal};
        ir_prev <= ir_sync[1];
    end

    // Detect rising edges
    wire ir_rise = ~ir_prev & ir_sync[1];

    // 10 ms timer (1,000,000 cycles at 100 MHz)
    reg [19:0] timer_counter;
    wire timer_pulse = (timer_counter == 20'd999_999);

    // Edge counter
    reg [15:0] edge_counter;
    reg [15:0] latched_count;

    always @(posedge clk) begin
        // Timer logic
        if (timer_pulse) begin
            timer_counter <= 0;
        end else begin
            timer_counter <= timer_counter + 1;
        end

        // Edge counter logic
        if (timer_pulse) begin
            edge_counter <= 0;
        end else if (ir_rise) begin
            edge_counter <= edge_counter + 1;
        end

        // Latch the count at the end of the period
        if (timer_pulse) begin
            latched_count <= edge_counter;
        end
    end

    // Frequency decoder with adjusted ranges
    always @(posedge clk) begin
        if (timer_pulse && disable1 != 1) begin
            case (latched_count)
                19, 20, 21:    HZ <= 2'b01; // 1 kHz (~10 edges)
                39,40,41   :   HZ <= 2'b10; // 2 kHz (~20 edges)
                59, 60, 61:   HZ <= 2'b11; // 3 kHz (~30 edges)
                default:      HZ <= 2'b00; // Invalid
            endcase
            if (HZFLAG != 2'b00)
                disable1 <= 1;
        end
    end

endmodule






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
    parameter TURN_LEFT = 5'b00111; // New state for left turn after servo wait
    parameter ADJUST_AFTER_TURN = 5'b01000; // New state to adjust after turn
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

    // State register and other registers
    reg [4:0] state;
    reg after_turn;
    reg AB;
    reg [27:0] timer2;
    reg skip;
    reg [27:0] Ftimer;
    reg [1:0] Example = 2'b01;
    reg [1:0] KHZ;
    reg [27:0] turn_timer; // Timer for turn duration

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
        end else begin
            case (state)
                STOP: begin
                    if (sensor_status[2:1] != 2'b00 && HZ != 2'b00) begin
                        state <= LINE_FOLLOW;
                        KHZ <= HZ;
                    end
                end
                LINE_FOLLOW: begin
                    if (turn_count == 1 && ~prox1)
                        state <= SERVO_WAIT;
                    else if (sensor_status[0] == 1'b1 && after_turn == 1)
                        state <= STOP_RIGHT; // Right turn after left turn
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
                    if (Ftimer < 50_000_000)
                        Ftimer <= Ftimer + 1;
                    else begin
                        Ftimer <= 0;
                        state <= LINE_FOLLOW;
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
                    if (sensor_status[2:1] == 2'b11) begin
                        if (after_turn == 1) begin
                            state <= LFTD; // After right turn, go to LFTD
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
                        state <= TURN_LEFT;
                        turn_timer <= 0;
                    end
                end
                TURN_LEFT: begin
                    if (turn_timer < 300_000_000) begin
                        turn_timer <= turn_timer + 1;
                        if (turn_timer >= 100_000_000 && sensor_status[2:1] != 2'b00)
                            state <= ADJUST_AFTER_TURN;
                    end else begin
                        state <= ADJUST_AFTER_TURN;
                        turn_timer <= 0;
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
                    if (sensor_status[2:1] == 2'b11 && turn_count == 1) begin
                        state <= LFTD;
                        after_turn <= 2;
                        turn_count <= 2;
                    end else if (sensor_status[2:1] == 2'b11 && turn_count == 2) begin
                        state <= delay;
                        after_turn <= 3;
                        turn_count <= 3;
                    end
                end
                LFTD: begin
                    if (~prox2)
                        state <= TOWER;
                end
                TOWER: begin
                    if (TD == 1)
                        state <= REVERSE;
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
            TURN_LEFT: begin
                stateL = 2'b10; // Forward left, reverse right for left turn
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
            default: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
        endcase
    end
endmodule









// almost done

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
    parameter TURN_LEFT = 5'b00111; // New state for left turn after servo wait
    parameter ADJUST_AFTER_TURN = 5'b01000; // New state to adjust after turn
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

    // State register and other registers
    reg [4:0] state;
    reg after_turn;
    reg AB;
    reg [27:0] timer2;
    reg skip;
    reg [27:0] Ftimer;
    reg [1:0] Example = 2'b01;
    reg [1:0] KHZ;
    reg [27:0] turn_timer; // Timer for turn duration

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
        end else begin
            case (state)
                STOP: begin
                    if (sensor_status[2:1] != 2'b00 && HZ != 2'b00) begin
                        state <= LINE_FOLLOW;
                        KHZ <= HZ;
                    end
                end
                LINE_FOLLOW: begin
                    if (turn_count == 1 && ~prox1)
                        state <= SERVO_WAIT;
                    else if (sensor_status[0] == 1'b1 && after_turn == 1)
                        state <= STOP_RIGHT; // Right turn after left turn
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
                    if (Ftimer < 50_000_000)
                        Ftimer <= Ftimer + 1;
                    else begin
                        Ftimer <= 0;
                        state <= LINE_FOLLOW;
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
                    if (sensor_status[2:1] == 2'b11) begin
                        if (after_turn == 1) begin
                            state <= LFTD; // After right turn, go to LFTD
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
                        state <= TURN_LEFT;
                        turn_timer <= 0;
                    end
                end
                TURN_LEFT: begin
                    if (turn_timer < 300_000_000) begin
                        turn_timer <= turn_timer + 1;
                        if (turn_timer >= 100_000_000 && sensor_status[2:1] != 2'b00)
                            state <= ADJUST_AFTER_TURN;
                    end else begin
                        state <= ADJUST_AFTER_TURN;
                        turn_timer <= 0;
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
                    if (sensor_status[2:1] == 2'b11 && turn_count == 1) begin
                        state <= LFTD;
                        after_turn <= 2;
                        turn_count <= 2;
                    end else if (sensor_status[2:1] == 2'b11 && turn_count == 2) begin
                        state <= delay;
                        after_turn <= 3;
                        turn_count <= 3;
                    end
                end
                LFTD: begin
                    if (~prox2)
                        state <= TOWER;
                end
                TOWER: begin
                    if (TD == 1)
                        state <= REVERSE;
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
            TURN_LEFT: begin
                stateL = 2'b10; // Forward left, reverse right for left turn
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
            default: begin
                stateL = 2'b00;
                stateR = 2'b00;
            end
        endcase
    end
endmodule






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
    parameter TURN_LEFT = 5'b00111;
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
    parameter FOLLOW_LINE_1SEC = 5'b10011;
    parameter REVERSE_AFTER_TOWER = 5'b10100; // New state for reversing after tower

    // State register and other registers
    reg [4:0] state;
    reg after_turn;
    reg AB;
    reg [27:0] timer2;
    reg skip;
    reg [27:0] Ftimer;
    reg [1:0] Example = 2'b01;
    reg [1:0] KHZ;
    reg [27:0] turn_timer; // Timer for turn duration
    reg [27:0] follow_timer; // Timer for 1-sec line following
    reg after_tower;         // Flag for post-TOWER sequence
    reg pending_right_turn;  // Flag for right turn after left
    reg to_transmit;         // Flag to trigger transmit

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
            follow_timer <= 0;
            after_tower <= 0;
            pending_right_turn <= 0;
            to_transmit <= 0;
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
                    state <= INIT_TURN_RIGHT;
                end
                INIT_TURN_RIGHT: begin
                    if (sensor_status[2:1] == 2'b00)
                        state <= ADJUST_TURN;
                end
                ADJUST_TURN: begin
                    if (sensor_status[2:1] == 2'b11) begin
                        if (pending_right_turn == 1) begin
                            state <= FOLLOW_LINE_1SEC;
                            pending_right_turn <= 0;
                            follow_timer <= 0;
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
                        state <= TURN_LEFT;
                        turn_timer <= 0;
                    end
                end
                TURN_LEFT: begin
                    if (turn_timer < 100_000_000) begin
                        turn_timer <= turn_timer + 1;
                    end else begin
                        if (done == 1 && sensor_status[2:1] != 2'b00) begin
                            state <= LINE_FOLLOW;
                            turn_timer <= 0;
                        end else if (turn_timer < 300_000_000) begin
                            turn_timer <= turn_timer + 1;
                            if (turn_timer >= 150_000_000 && sensor_status[2:1] != 2'b00)
                                state <= ADJUST_AFTER_TURN;
                        end else begin
                            state <= ADJUST_AFTER_TURN;
                            turn_timer <= 0;
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
                    if (~prox2)
                        state <= TOWER;
                end
                TOWER: begin
                    if (TD == 1) begin
                        state <= REVERSE_AFTER_TOWER;
                        Ftimer <= 0;
                        after_tower <= 1;
                    end
                end
                REVERSE_AFTER_TOWER: begin
                    if (Ftimer < 150_000_000) begin
                        Ftimer <= Ftimer + 1;
                    end else begin
                        state <= TURN_LEFT;
                        turn_timer <= 0;
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
                FOLLOW_LINE_1SEC: begin
                    if (follow_timer < 100_000_000) begin
                        follow_timer <= follow_timer + 1;
                    end else begin
                        state <= STOP;
                        follow_timer <= 0;
                        to_transmit <= 1;
                    end
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
            TURN_LEFT: begin
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
            FOLLOW_LINE_1SEC: begin
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
        endcase
    end
endmodule







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
    parameter TURN_LEFT = 5'b00111;
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
    parameter FOLLOW_LINE_1SEC = 5'b10011;
    parameter REVERSE_AFTER_TOWER = 5'b10100;
    parameter REVERSE_LINE_FOLLOW = 5'b10101;  // New state for reverse line following
    parameter STOP_DELAY = 5'b10110;           // New state for 0.5 sec stop
    parameter TURN_IGNORE_SENSORS = 5'b10111;  // New state for turn with sensor ignore

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
    reg [27:0] follow_timer;       // Timer for 1-sec line following
    reg [27:0] stop_timer;         // Timer for 0.5 sec stop
    reg [27:0] ignore_timer;       // Timer for 2-sec sensor ignore
    reg [27:0] reverse_timer;      // Timer for 2-sec minimum reverse
    reg after_tower;               // Flag for post-TOWER sequence
    reg pending_right_turn;        // Flag for right turn after left
    reg to_transmit;               // Flag to trigger transmit
    reg reverse_after_servo;       // Flag for post-SERVO sequence
    reg skip_first_intersection;   // Flag to skip first intersection after tower
    reg ignore_sensors;            // Flag to ignore sensors during turn

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
            follow_timer <= 0;
            stop_timer <= 0;
            ignore_timer <= 0;
            reverse_timer <= 0;
            after_tower <= 0;
            pending_right_turn <= 0;
            to_transmit <= 0;
            reverse_after_servo <= 0;
            skip_first_intersection <= 0;
            ignore_sensors <= 0;
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
                    state <= INIT_TURN_RIGHT;
                end
                INIT_TURN_RIGHT: begin
                    if (sensor_status[2:1] == 2'b00)
                        state <= ADJUST_TURN;
                end
                ADJUST_TURN: begin
                    if (sensor_status[2:1] == 2'b11) begin
                        if (pending_right_turn == 1) begin
                            state <= FOLLOW_LINE_1SEC;
                            pending_right_turn <= 0;
                            follow_timer <= 0;
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
                        state <= REVERSE_LINE_FOLLOW;
                        reverse_after_servo <= 1;
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
                        if (reverse_after_servo == 0 && after_tower == 0) begin
                            // After servo path
                            state <= TURN_IGNORE_SENSORS;
                            ignore_timer <= 0;
                            ignore_sensors <= 1;
                        end else begin
                            // After tower path
                            state <= TURN_IGNORE_SENSORS;
                            ignore_timer <= 0;
                            ignore_sensors <= 1;
                        end
                    end
                end
                TURN_IGNORE_SENSORS: begin
                    if (ignore_timer < 200_000_000) begin
                        // 2 sec period where sensors are ignored
                        ignore_timer <= ignore_timer + 1;
                    end else if ((sensor_status[2:1] != 2'b00) && (sensor_status[2:1] != 2'b11)) begin
                        ignore_sensors <= 0;
                        if (after_tower == 0 && reverse_after_servo == 0) begin
                            // After servo path
                            state <= LFTD;
                        end else begin
                            // After tower path
                            state <= FOLLOW_LINE_1SEC;
                            follow_timer <= 0;
                        end
                    end
                end
                TURN_LEFT: begin
                    if (turn_timer < 100_000_000) begin
                        turn_timer <= turn_timer + 1;
                    end else begin
                        if (done == 1 && sensor_status[2:1] != 2'b00) begin
                            state <= LINE_FOLLOW;
                            turn_timer <= 0;
                        end else if (turn_timer < 300_000_000) begin
                            turn_timer <= turn_timer + 1;
                            if (turn_timer >= 150_000_000 && sensor_status[2:1] != 2'b00)
                                state <= ADJUST_AFTER_TURN;
                        end else begin
                            state <= ADJUST_AFTER_TURN;
                            turn_timer <= 0;
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
                    if (~prox2)
                        state <= TOWER;
                end
                TOWER: begin
                    if (TD == 1) begin
                        state <= REVERSE_AFTER_TOWER;
                        Ftimer <= 0;
                        after_tower <= 1;
                        reverse_timer <= 0;  // Reset reverse timer for 2-second minimum
                    end
                end
                REVERSE_AFTER_TOWER: begin
                    if (Ftimer < 50_000_000) begin
                        Ftimer <= Ftimer + 1;
                    end else begin
                        state <= REVERSE_LINE_FOLLOW;
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
                FOLLOW_LINE_1SEC: begin
                    if (follow_timer < 100_000_000) begin
                        follow_timer <= follow_timer + 1;
                    end else begin
                        state <= STOP;
                        follow_timer <= 0;
                        to_transmit <= 1;
                    end
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
            TURN_LEFT, TURN_IGNORE_SENSORS: begin
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
            FOLLOW_LINE_1SEC: begin
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