module line_follower_top(
    input clk,
    input rst,
    input Msensor1,      // Front left sensor
    input Msensor2,      // Front right sensor
    input Lsensor,       // Left side sensor
    input Rsensor,       // Back middle sensor
    output enA,          
    output enB,          
    output in1,          
    output in2,          
    output in3,          
    output in4           // Removed extra comma here
);
    // Internal wires
    wire [7:0] counter;  // Added semicolon here
    wire [3:0] sensor_out;
    wire [1:0] stateL, stateR;

    // Instantiate sensor module
    sensor sensor_inst(
        .Msensor1(Msensor1),
        .Msensor2(Msensor2),
        .Lsensor(Lsensor),
        .Rsensor(Rsensor),
        .sensor_out(sensor_out)
    );

    // Instantiate state machine
    state_machine state_machine_inst(
        .clk(clk),
        .rst(rst),
        .sensor_out(sensor_out),
        .stateL(stateL),
        .stateR(stateR),
        .counter(counter)
    );

    // Instantiate motor control
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