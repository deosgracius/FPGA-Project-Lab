`include"sensor.v"
`include "state_m.v"
`include "modulemotorcontrol.v"

module top_module (
    // System clock (and reset if needed)
    input clk,
    // Sensor inputs
    input left,
    input front,
    input right,
    input back,
    // Motor enable signals
    output enA,
    output enB,
    // Motor control outputs
    output [1:0] MotorL,
    output [1:0] MotorR
);

    wire [3:0] location;     
    // Instantiate Sensor Module
    sensor sensor_inst (.left(left), .front(front), .right(right), .back(back), .location(location));

    // Instantiate State Machine Module
    state_m state_machine_inst (.clk(clk), .location(location), .motorcontrol(motorcontrol));
    wire [1:0] motorcontrol; 
    // Instantiate Motor Control Module
    motorcontrol motor_inst (.clk(clk), .motorcontrol(motorcontrol), .enA(enA), .enB(enB), .MotorL(MotorL), .MotorR(MotorR));

endmodule

