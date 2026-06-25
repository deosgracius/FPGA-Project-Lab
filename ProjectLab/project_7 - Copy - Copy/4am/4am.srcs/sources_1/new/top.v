module top(
    input clk,              // System clock
    //input reset,           // System reset
    input Msensor1,        // Front left sensor
    input Msensor2,        // Front right sensor
    input Lsensor,         // Left side sensor
    input Rsensor,         // Back middle sensor
    output enA,            // Enable motor A
    output enB,            // Enable motor B
    output in1,            // Motor control input 1
    output in2,            // Motor control input 2
    output in3,            // Motor control input 3
    output in4             // Motor control input 4
);

    // Internal wires for connecting modules
    wire [3:0] sensor_out;
    wire [1:0] stateL;
    wire [1:0] stateR;
    //wire [1:0] counter

    // Instantiate sensor module
    sensor SENSOR(
        .Msensor1(Msensor1),
        .Msensor2(Msensor2),
        .Lsensor(Lsensor),
        .Rsensor(Rsensor),
        .sensor_out(sensor_out)
    );

    // Instantiate line follower module
    line_follower line_follower_inst(
        .clk(clk),
        //.reset(reset),
        .sensor_out(sensor_out),
        .stateL(stateL),
        .stateR(stateR)
    );

    // Instantiate motor control module
    motor_control motor_control_inst(
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