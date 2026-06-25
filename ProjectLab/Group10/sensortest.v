`timescale 1ns / 1ps
`include "sensor.v"
module sensor_tb;

    // Inputs
    reg left;
    reg front;
    reg right;
    reg back;

    // Outputs
    wire [3:0] location;

    // Instantiate the Unit Under Test (UUT)
    sensor uut (
        .left(left),
        .front(front),
        .right(right),
        .back(back),
        .location(location)
    );

    initial begin
        // Initialize Inputs
        left = 0;
        front = 0;
        right = 0;
        back = 0;

        // Apply test vectors
        #10 left = 1; front = 1; right = 1; back = 1; // online
        #10 left = 1; front = 0; right = 1; back = 1; // leftline
        #10 left = 1; front = 1; right = 1; back = 0; // rightline
        #10 left = 1; front = 0; right = 1; back = 0; // intersection
        #10 left = 0; front = 0; right = 0; back = 0; // default

        // End simulation
        #10 $finish;
    end
      
    initial begin
        // Monitor the inputs and outputs
        $monitor("Time: %d, left: %b, front: %b, right: %b, back: %b, location: %b", $time, left, front, right, back, location);
    end
    initial begin
    // Initialize the output file for the waveform trace
    $dumpfile("sensor_waveform.vcd");  // Specify the name of the output file
    $dumpvars(0, sensor_tb);           // Dump all variables in the sensor_tb module

    // Run the simulation for a specified time
    #100 $finish;  // Adjust the simulation time as needed
end

endmodule
