`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2025 09:20:13 PM
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module tb_Rover5;
    // Testbench signals
    reg clk;
    reg reset;
    reg sensor_west;
    reg sensor_east;

    wire sensor_or;
    wire [3:0] counter;
    wire motor_enable_a;
    wire motor_enable_b;
    wire in1, in2, in3, in4;
    wire m1, m2;

    //-----------------------------------------
    // Instantiate Sensor Behavior
    //-----------------------------------------
    SensorBehavior sb (
        .sensor_west(sensor_west),
        .sensor_east(sensor_east),
        .sensor_or(sensor_or)   // Not strictly needed in the testbench, but here for completeness
    );

    //-----------------------------------------
    // Instantiate StateCases (the main state machine)
    //-----------------------------------------
    StateCases sc (
        .clk(clk),
        .reset(reset),
        .sensor_west(sensor_west),
        .sensor_east(sensor_east),
        .counter(counter),
        .motor_enable_a(motor_enable_a),
        .motor_enable_b(motor_enable_b),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .in4(in4)
    );

    //-----------------------------------------
    // Instantiate Motor Control
    //-----------------------------------------
    MotorControl mc (
        .enable_a(motor_enable_a),
        .enable_b(motor_enable_b),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .in4(in4),
        .m1(m1),
        .m2(m2)
    );

    //-----------------------------------------
    // Generate a clock
    //-----------------------------------------
    always #5 clk = ~clk;  // 10 ns period => 100 MHz clock

    //-----------------------------------------
    // Test Sequence
    //-----------------------------------------
    initial begin
        // Initial conditions
        clk         = 1'b0;
        reset       = 1'b1;
        sensor_west = 1'b0;
        sensor_east = 1'b0;

        // Hold reset active for a short time
        #10;
        reset = 1'b0;  // De-assert reset

        // After reset, the rover is set to move forward by default
        // Let's change sensor inputs to see the reaction

        // 1) Only left sensor on
        #20;
        sensor_west = 1'b1; // left sensor
        sensor_east = 1'b0;

        // 2) Only right sensor on
        #20;
        sensor_west = 1'b0;
        sensor_east = 1'b1;

        // 3) Both sensors on => intersection
        #20;
        sensor_west = 1'b1;
        sensor_east = 1'b1;

        // 4) No sensor => forward
        #20;
        sensor_west = 1'b0;
        sensor_east = 1'b0;

        // 5) Another intersection
        #20;
        sensor_west = 1'b1;
        sensor_east = 1'b1;

        // End simulation
        #50;
        $finish;
    end

    //-----------------------------------------
    // Monitor outputs
    //-----------------------------------------
    initial begin
        $monitor($time,
            " | Reset=%b W=%b E=%b Count=%d | EnA=%b EnB=%b | in1=%b in2=%b in3=%b in4=%b | m1=%b m2=%b",
            reset, sensor_west, sensor_east, counter,
            motor_enable_a, motor_enable_b,
            in1, in2, in3, in4,
            m1, m2
        );
    end

endmodule

