module top (
    input clk,           // 100 MHz clock
    input sensor_left,   // Left sensor (active low)
    input sensor_right,  // Right sensor (active low)
    input sensor_T,      // T-sensor (active low)
    input prox1,         // Proximity sensor 1 (active low)
    input prox2,         // Proximity sensor 2 (active low)
    input prox3,         // Limit switch
    input ir_signal,     // IR receiver input
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
    wire [1:0] HZ;
    wire [1:0] stateL, stateR;
    wire [2:0] intersection_count, turn_count, target_intersection;
    wire [4:0] current_state;
    wire done, TD, THZ, go_flag;

    // Instantiate IR receiver (placeholder)
    ir_receiver ir (
        .clk(clk),
        .ir_signal(ir_signal),
        .HZ(HZ)
    );

    // Instantiate sensor module (placeholder)
    sensor_module sensors (
        .sensor_left(sensor_left),
        .sensor_right(sensor_right),
        .sensor_T(sensor_T),
        .sensor_status(sensor_status)
    );

    // Instantiate servo controller (placeholder)
    servo_controller serv (
        .clk(clk),
        .prox1(prox1),
        .prox2(prox2),
        .prox3(prox3),
        .pwm_out(pwm_servo),
        .mosfet(mosfet),
        .done(done),
        .TD(TD)
    );

    // Instantiate rover controller (placeholder with intersection_count output)
    rover_controller controller (
        .clk(clk),
        //.rst(1'b0), // No external reset for simplicity
        .sensor_status(sensor_status),
        .prox1(prox1),
        .done(done),
        .prox2(prox2),
        .TD(TD),
        .HZ(HZ),
        .prox3(prox3),
        .stateL(stateL),
        .stateR(stateR),
        .intersection_count(intersection_count),
        .turn_count(turn_count),
        .current_state(current_state),
        .THZ(THZ)
        //.target_intersection(target_intersection),
        //.go_flag(go_flag)
    );

    // Instantiate motor control (placeholder)
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

    // Instantiate seven-segment decoder
    seven_seg_decoder display (
        .digit({1'b0, intersection_count}), // Zero-extend 3-bit intersection_count to 4 bits
        .seg(seg)
    );

    // LED assignments (for debugging or visualization)
    assign led[0] = (HZ == 2'b00);  // Invalid
    assign led[1] = (HZ == 2'b01);  // 1kHz
    assign led[2] = (HZ == 2'b10);  // 2kHz
    assign led[3] = (HZ == 2'b11);  // 3kHz
    assign led[5] = (target_intersection == 2);  // LED 5 for target_intersection == 2
    assign led[6] = (target_intersection == 3);  // LED 6 for target_intersection == 3
    assign led[7] = (target_intersection == 4);  // LED 7 for target_intersection == 4
    assign led[4] = 1'b0;          // Turn off LED 4
    assign led[12:8] = current_state; // Current state (5 bits)
    assign led[14:13] = 2'b00;     // Off
    assign led[15] = go_flag;      // LED 15 for go_flag

    // Seven-segment anode control (active low, only rightmost digit enabled)
    assign an = 4'b1110;           // Enable only the rightmost digit
endmodule

