`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/29/2025 06:50:43 PM
// Design Name: 
// Module Name: Testbench
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



// Include required module files
`include "Sensormodule.v"
`include "MotorControl.v"
`include "States_Cases.v"

module rover_tb();
    // Test bench signals
    reg clck;                  // System clock
    reg rst;                  // Reset signal
    reg sensor_west;           // Left sensor
    reg sensor_east;           // Right sensor
    
    // Output monitoring
    wire [1:0] sensor_state;   // From sensor module
    wire [3:0] control_signals; // To motor control
    wire enable_a;             // Motor 1 enable
    wire enable_b;             // Motor 2 enable
    wire [1:0] motor1_control; // Motor 1: {In1,In3}
    wire [1:0] motor2_control; // Motor 2: {In2,In4}
    wire [2:0] intersection_counter;

    // Task for displaying current state
    task display_state;
        begin
            $display("\nTime=%0t", $time);
            $display("Sensors: West=%b East=%b → State=%b", 
                     sensor_west, sensor_east, sensor_state);
            $display("Motor1 Control: {In1,In3}=%b", motor1_control);
            $display("Motor2 Control: {In2,In4}=%b", motor2_control);
            $display("Intersection Counter=%d", intersection_counter);
            $display("-----------------------------------------");
        end
    endtask

    // Instantiate modules from separate files
    sensor_behavior SENSORS(
        .sensor_west(sensor_west),
        .sensor_east(sensor_east),
        .sensor_state(sensor_state)
    );

    motor_control MOTORS(
        .control_signals(control_signals),
        .enable_a(enable_a),
        .enable_b(enable_b),
        .motor1_control(motor1_control),
        .motor2_control(motor2_control)
    );

    state_machine CONTROL(
        .clck(clck),
        .rst(rst),
        .sensor_state(sensor_state),
        .control_signals(control_signals),
        .intersection_counter(intersection_counter)
    );

    // Clock generation (50MHz)
    initial begin
        clck = 0;
        forever #10 clck = ~clck;
    end

    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("rover_test.vcd");
        $dumpvars(0, rover_tb);

        // Initialize log file
        $display("\nStarting Rover Test Cases");
        $display("==========================");

        // Test 1: Reset State
        $display("\n=== Test 1: Reset State ===");
        rst = 1;
        sensor_west = 0;
        sensor_east = 0;
        #20;
        display_state();

        // Test 2: Start Line Following
        $display("\n=== Test 2: Basic Line Following ===");
        rst = 0;
        sensor_west = 0;
        sensor_east = 0;
        #20;
        display_state();

        // Test 3: Left Sensor Detection
        $display("\n=== Test 3: Left Sensor Only ===");
        sensor_west = 1;
        sensor_east = 0;
        #20;
        display_state();

        // Test 4: Back to Center
        $display("\n=== Test 4: Return to Center ===");
        sensor_west = 0;
        sensor_east = 0;
        #20;
        display_state();

        // Test 5: Right Sensor Detection
        $display("\n=== Test 5: Right Sensor Only ===");
        sensor_west = 0;
        sensor_east = 1;
        #20;
        display_state();

        // Test 6: First Intersection (Turn Left)
        $display("\n=== Test 6: First Intersection - Turn Left ===");
        sensor_west = 1;
        sensor_east = 1;
        #20;
        display_state();
        
        // Return to line following
        sensor_west = 0;
        sensor_east = 0;
        #20;
        display_state();

        // Test 7: Second Intersection (Turn Right)
        $display("\n=== Test 7: Second Intersection - Turn Right ===");
        sensor_west = 1;
        sensor_east = 1;
        #20;
        display_state();
        
        // Return to line following
        sensor_west = 0;
        sensor_east = 0;
        #20;
        display_state();

        // Test 8: Third Intersection (Forward)
        $display("\n=== Test 8: Third Intersection - Forward ===");
        sensor_west = 1;
        sensor_east = 1;
        #20;
        display_state();
        
        // Return to line following
        sensor_west = 0;
        sensor_east = 0;
        #20;
        display_state();

        // Test 9: Fourth Intersection (Reverse)
        $display("\n=== Test 9: Fourth Intersection - Reverse ===");
        sensor_west = 1;
        sensor_east = 1;
        #20;
        display_state();
        
        // Return to line following
        sensor_west = 0;
        sensor_east = 0;
        #20;
        display_state();

        // Test 10: Fifth Intersection (Stop)
        $display("\n=== Test 10: Fifth Intersection - Stop ===");
        sensor_west = 1;
        sensor_east = 1;
        #20;
        display_state();

        // Test complete
        #20;
        $display("\n=== Test Complete ===");
        $finish;
    end

    // Monitor changes and verify behavior
    always @(sensor_state or control_signals or intersection_counter) begin
        case(control_signals)
            4'b0101: $display("Action: Forward");
            4'b1101: $display("Action: Turn Left");
            4'b0111: $display("Action: Turn Right");
            4'b1010: $display("Action: Reverse");
            4'b1111: $display("Action: Stop");
            default: $display("Action: Unknown state");
        endcase
    end

    // Additional verification
    always @(posedge clck) begin
        // Verify enables are always on
        if (!enable_a || !enable_b)
            $display("ERROR: Motor enables should always be HIGH");
            
        // Verify valid motor control signals
        if (^motor1_control === 1'bx || ^motor2_control === 1'bx)
            $display("ERROR: Invalid motor control signals detected");
            
        // Verify intersection counter doesn't exceed 5
        if (intersection_counter > 3'b100)
            $display("ERROR: Intersection counter exceeded maximum value");
    end
endmodule
