

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



module rover_controller(
    input clk,                  // Clock input
    input rst,                  // Reset input (active high)
    input [2:0] sensor_status,  // [left, right, T] from sensor_module
    output reg [1:0] stateL,    // Left motor state: 2'b00 stop, 2'b10 forward, 2'b01 reverse
    output reg [1:0] stateR     // Right motor state: 2'b00 stop, 2'b10 forward, 2'b01 reverse
);

    // Define states using parameters (using 3 bits)
    parameter STOP = 3'b000;
    parameter LINE_FOLLOW = 3'b001;
    parameter STOP_RIGHT = 3'b010;
    parameter INIT_TURN_RIGHT = 3'b011;
    parameter ADJUST_TURN = 3'b100;
    parameter REVERSE = 3'b101;  // Reintroduced REVERSE state

    // State register (3 bits)
    reg [2:0] state;

    // Sequential logic for state transitions
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STOP;      // Reset to STOP state
        end else begin
            case (state)
                STOP: begin
                    if (sensor_status[2:1] != 2'b00) begin
                        state <= LINE_FOLLOW;  // Start when any front sensor detects the line
                    end
                end
                LINE_FOLLOW: begin
                    if (sensor_status[0] == 1'b1) begin  // T-sensor detects intersection
                        state <= STOP_RIGHT;  // Stop before turning right
                    end else if (sensor_status[2:1] == 2'b00) begin  // Both front sensors lose the line
                        state <= REVERSE;  // Reverse until a sensor detects the line
                    end
                end
                STOP_RIGHT: begin
                    state <= INIT_TURN_RIGHT;  // After stopping, immediately start turning right
                end
                INIT_TURN_RIGHT: begin
                    // Transition to ADJUST_TURN after initiating the turn
                    state <= ADJUST_TURN;
                end
                ADJUST_TURN: begin
                    if (sensor_status[2:1] == 2'b11) begin  // Both front sensors detect the new line
                        state <= LINE_FOLLOW;  // Turn complete, resume line following
                    end
                    // Stay in ADJUST_TURN otherwise to continue adjusting
                end
                REVERSE: begin
                    if (sensor_status[2:1] != 2'b00) begin  // At least one front sensor detects the line
                        state <= LINE_FOLLOW;  // Resume line following
                    end
                    // Stay in REVERSE otherwise
                end
            endcase
        end
    end

    // Combinational logic for motor outputs
    always @(*) begin
        case (state)
            STOP: begin
                stateL = 2'b00;  // Left motor stop
                stateR = 2'b00;  // Right motor stop
            end
            LINE_FOLLOW: begin
                case (sensor_status[2:1])
                    2'b11: begin  // Both sensors on the line
                        stateL = 2'b10;  // Left motor forward
                        stateR = 2'b10;  // Right motor forward
                    end
                    2'b10: begin  // Left sensor on, right sensor off
                        stateL = 2'b10;  // Left motor forward
                        stateR = 2'b00;  // Right motor stop (turn right)
                    end
                    2'b01: begin  // Right sensor on, left sensor off
                        stateL = 2'b00;  // Left motor stop
                        stateR = 2'b10;  // Right motor forward (turn left)
                    end
                    default: begin  // No sensors on the line (handled by state transition to REVERSE)
                        stateL = 2'b00;  // Left motor stop (temporary until state changes)
                        stateR = 2'b00;  // Right motor stop (temporary until state changes)
                    end
                endcase
            end
            STOP_RIGHT: begin
                stateL = 2'b00;  // Left motor stop
                stateR = 2'b00;  // Right motor stop
            end
            INIT_TURN_RIGHT: begin
                stateL = 2'b01;  // Left motor forward
                stateR = 2'b10;  // Right motor reverse (start sharp right turn)
            end
            ADJUST_TURN: begin
                case (sensor_status[2:1])
                    2'b00: begin  // No sensors detect
                        stateL = 2'b01;  // Left motor forward
                        stateR = 2'b10;  // Right motor reverse (continue turning right)
                    end
                    2'b10: begin  // Left sensor detects
                        stateL = 2'b10;  // Left motor stop
                        stateR = 2'b00;  // Right motor forward (adjust left)
                    end
                    2'b01: begin  // Right sensor detects
                        stateL = 2'b00;  // Left motor forward
                        stateR = 2'b10;  // Right motor stop (adjust right)
                    end
                    2'b11: begin  // Both sensors detect
                        stateL = 2'b10;  // Left motor forward
                        stateR = 2'b10;  // Right motor forward (ready for LINE_FOLLOW)
                    end
                endcase
            end
            REVERSE: begin
                stateL = 2'b01;  // Left motor reverse
                stateR = 2'b01;  // Right motor reverse
            end
        endcase
    end

endmodule

module top(

    input clk,           // Clock input

    //input rst,           // Reset input

    input sensor_left,   // Left sensor (active low)

    input sensor_right,  // Right sensor (active low)

    input sensor_T,      // T-sensor (active low)

    output enA,          // Left motor enable

    output enB,          // Right motor enable

    output in1,          // Left motor forward

    output in2,          // Left motor backward

    output in3,          // Right motor forward

    output in4           // Right motor backward

);

 

    // Internal wires

    wire [2:0] sensor_status;  // [left, right, T]

    wire [1:0] stateL;         // Left motor state

    wire [1:0] stateR;         // Right motor state

 

    // Instantiate sensor_module

    sensor_module sensors(

        .sensor_left(sensor_left),

        .sensor_right(sensor_right),

        .sensor_T(sensor_T),

        .sensor_status(sensor_status)

    );

 

    // Instantiate rover_controller

    rover_controller controller(

        .clk(clk),

        //.rst(rst),

        .sensor_status(sensor_status),

        .stateL(stateL),

        .stateR(stateR)

    );

 

    // Instantiate motor_control

    motor_control motors(

        .stateL(stateL),

        .stateR(stateR),

        .enA(enA),

        .enB(enB),

        .in1(in1),

        .in2(in2),

        .in3(in3),

        .in4(in4)

    );

 

endmodule


## Clock signal
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]


##Pmod Header JXADC
#set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports {JXADC[0]}];#Sch name = XA1_P
set_property -dict { PACKAGE_PIN L3   IOSTANDARD LVCMOS33 } [get_ports {enB}];#Sch name = XA2_P
set_property -dict { PACKAGE_PIN M2   IOSTANDARD LVCMOS33 } [get_ports {in4}];#Sch name = XA3_P
set_property -dict { PACKAGE_PIN N2   IOSTANDARD LVCMOS33 } [get_ports {in2}];#Sch name = XA4_P
set_property -dict { PACKAGE_PIN K3   IOSTANDARD LVCMOS33 } [get_ports {enA}];#Sch name = XA1_N
#set_property -dict { PACKAGE_PIN M3   IOSTANDARD LVCMOS33 } [get_ports {Ir_input}];#Sch name = XA2_N
set_property -dict { PACKAGE_PIN M1   IOSTANDARD LVCMOS33 } [get_ports {in3}];#Sch name = XA3_N
set_property -dict { PACKAGE_PIN N1   IOSTANDARD LVCMOS33 } [get_ports {in1}];#Sch name = XA4_N

##Pmod Header JC
#set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports {proximity_in}];#Sch name = JC1
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports {sensor_T}];#Sch name = JC2
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports {sensor_right}];#Sch name = JC3
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports {sensor_left}];#Sch name = JC4
#set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports {servo_pwm}];#Sch name = JC7
#set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVCMOS33 } [get_ports {dc_motor_pwm}];#Sch name = JC8
#set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports {emergency_btn}];#Sch name = JC9
#set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports {JC[7]}];#Sch name = JC10






// Turn Left 




module rover_controller(
    input clk,                  // Clock input
    input rst,                  // Reset input (active high)
    input [2:0] sensor_status,  // [left, right, T] from sensor_module
    output reg [1:0] stateL,    // Left motor state: 2'b00 stop, 2'b10 forward, 2'b01 reverse
    output reg [1:0] stateR     // Right motor state: 2'b00 stop, 2'b10 forward, 2'b01 reverse
);

    // Define states using parameters (using 3 bits)
    parameter STOP = 3'b000;
    parameter LINE_FOLLOW = 3'b001;
    parameter STOP_RIGHT = 3'b010;
    parameter INIT_TURN_RIGHT = 3'b011;
    parameter ADJUST_TURN = 3'b100;

    // State register (3 bits)
    reg [2:0] state;

    // Sequential logic for state transitions
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STOP;      // Reset to STOP state
        end else begin
            case (state)
                STOP: begin
                    if (sensor_status[2:1] != 2'b00) begin
                        state <= LINE_FOLLOW;  // Start when any front sensor detects the line
                    end
                end
                LINE_FOLLOW: begin
                    if (sensor_status[0] == 1'b1) begin  // T-sensor detects intersection
                        state <= STOP_RIGHT;  // Stop before turning right
                    end
                    // Transition to REVERSE removed here
                end
                STOP_RIGHT: begin
                    state <= INIT_TURN_RIGHT;  // After stopping, start turning right
                end
                INIT_TURN_RIGHT: begin
                    state <= ADJUST_TURN;  // Proceed to adjust the turn
                end
                ADJUST_TURN: begin
                    if (sensor_status[2:1] == 2'b11) begin  // Both front sensors detect the new line
                        state <= LINE_FOLLOW;  // Turn complete, resume line following
                    end
                    // Stay in ADJUST_TURN otherwise
                end
            endcase
        end
    end

    // Combinational logic for motor outputs
    always @(*) begin
        case (state)
            STOP: begin
                stateL = 2'b00;  // Left motor stop
                stateR = 2'b00;  // Right motor stop
            end
            LINE_FOLLOW: begin
                case (sensor_status[2:1])
                    2'b11: begin  // Both sensors on the line
                        stateL = 2'b10;  // Left motor forward
                        stateR = 2'b10;  // Right motor forward
                    end
                    2'b10: begin  // Left sensor on, right sensor off
                        stateL = 2'b10;  // Left motor forward
                        stateR = 2'b00;  // Right motor stop (turn right)
                    end
                    2'b01: begin  // Right sensor on, left sensor off
                        stateL = 2'b00;  // Left motor stop
                        stateR = 2'b10;  // Right motor forward (turn left)
                    end
                    default: begin  // Both sensors off (2'b00)
                        stateL = 2'b00;  // Left motor stop
                        stateR = 2'b00;  // Right motor stop
                    end
                endcase
            end
            STOP_RIGHT: begin
                stateL = 2'b00;  // Left motor stop
                stateR = 2'b00;  // Right motor stop
            end
            INIT_TURN_RIGHT: begin
                stateL = 2'b10;  // Left motor forward
                stateR = 2'b01;  // Right motor reverse (start right turn)
            end
            ADJUST_TURN: begin
                case (sensor_status[2:1])
                    2'b00: begin  // No sensors detect
                        stateL = 2'b10;  // Left motor forward
                        stateR = 2'b01;  // Right motor reverse (continue turning right)
                    end
                    2'b10: begin  // Left sensor detects
                        stateL = 2'b10;  // Left motor forward
                        stateR = 2'b00;  // Right motor stop (adjust left)
                    end
                    2'b01: begin  // Right sensor detects
                        stateL = 2'b00;  // Left motor stop
                        stateR = 2'b10;  // Right motor forward (adjust right)
                    end
                    2'b11: begin  // Both sensors detect
                        stateL = 2'b10;  // Left motor forward
                        stateR = 2'b10;  // Right motor forward (ready for LINE_FOLLOW)
                    end
                endcase
            end
        endcase
    end

endmodule