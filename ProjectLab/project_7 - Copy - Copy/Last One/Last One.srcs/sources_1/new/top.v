module top1(
    input clk,
    input reset,
    input Msensor1,     // Front left sensor
    input Msensor2,     // Front right sensor
    input Lsensor,      // Left side sensor for intersection detection
    input Rsensor,      // Back middle sensor
    output enA,         // Motor enable A (left motor)
    output enB,         // Motor enable B (right motor)
    output in1,         // Left motor control
    output in2,
    output in3,         // Right motor control
    output in4
);

    wire [3:0] sensor_data;
    wire [1:0] motor_stateL, motor_stateR;

    // Instantiate sensor module
    s1 SENSOR(
        .Msensor1(Msensor1),
        .Msensor2(Msensor2),
        .Lsensor(Lsensor),
        .Rsensor(Rsensor),
        .sensor_out(sensor_data)
    );

    // Instantiate line follower module
    lf LINE_FOLLOWER(
        .clk(clk),
        .reset(reset),
        .sensor_out(sensor_data),
        .stateL(motor_stateL),
        .stateR(motor_stateR)
    );

    // Instantiate motor control module
    motor_control MOTOR_CONTROL(
        .stateL(motor_stateL),
        .stateR(motor_stateR),
        .enA(enA),
        .enB(enB),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .in4(in4)
    );

endmodule