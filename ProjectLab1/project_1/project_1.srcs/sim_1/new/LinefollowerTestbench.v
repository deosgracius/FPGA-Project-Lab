`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/21/2025 01:44:07 PM
// Design Name: 
// Module Name: LinefollowerTestbench
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

module LinefollowerTestbench;
    // Inputs
    reg clk;
    reg reset;
    reg [1:0] front_sensors;
    reg back_sensor;
    
    // Outputs
    wire [1:0] motor_left;
    wire [1:0] motor_right;
    
    // Instantiate the top module
    top uut (
        .clk(clk),
        .reset(reset),
        .front_sensors(front_sensors),
        .back_sensor(back_sensor),
        .motor_left(motor_left),
        .motor_right(motor_right)
    );
    
    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize inputs
        reset = 1;
        front_sensors = 2'b00;
        back_sensor = 0;
        
        // Wait for 100ns
        #100;
        
        // Release reset
        reset = 0;
        #100;
        
        // Test 1: Basic line following
        $display("Test 1: Basic line following");
        front_sensors = 2'b11; // Line detected by both sensors
        #1000;
        front_sensors = 2'b10; // Line on left
        #1000;
        front_sensors = 2'b01; // Line on right
        #1000;
        
        // Test 2: First intersection (Left Turn)
        $display("Test 2: First intersection");
        front_sensors = 2'b11;
        back_sensor = 1;
        #60000; // Wait for debounce and turn
        back_sensor = 0;
        #1000;
        
        // Test 3: Second intersection (Right Turn)
        $display("Test 3: Second intersection");
        front_sensors = 2'b11;
        back_sensor = 1;
        #60000;
        back_sensor = 0;
        #1000;
        
        // Test 4: Third intersection (Straight)
        $display("Test 4: Third intersection");
        front_sensors = 2'b11;
        back_sensor = 1;
        #60000;
        back_sensor = 0;
        #1000;
        
        // Test 5: Fourth intersection (Reverse)
        $display("Test 5: Fourth intersection");
        front_sensors = 2'b11;
        back_sensor = 1;
        #60000;
        back_sensor = 0;
        #1000;
        
        // Test 6: Fifth intersection (Stop)
        $display("Test 6: Fifth intersection");
        front_sensors = 2'b11;
        back_sensor = 1;
        #60000;
        
        // End simulation
        #1000;
        $finish;
    end
    
    // Monitor changes
    always @(posedge clk) begin
        if (uut.intersection_detected) begin
            $display("Time=%0t: Intersection detected! Count=%d", 
                    $time, uut.intersection_counter);
            $display("Current State=%d", uut.current_state);
            $display("Motors: Left=%b Right=%b", motor_left, motor_right);
            $display("--------------------");
        end
    end
    
    // Monitor state changes
    always @(uut.current_state) begin
        case(uut.current_state)
            3'd0: $display("State: FOLLOWING_LINE");
            3'd1: $display("State: TURNING_LEFT");
            3'd2: $display("State: TURNING_RIGHT");
            3'd3: $display("State: GOING_STRAIGHT");
            3'd4: $display("State: REVERSING");
            3'd5: $display("State: STOPPED");
            default: $display("State: UNKNOWN");
        endcase
    end
    
endmodule