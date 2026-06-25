`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/30/2025 12:25:20 AM
// Design Name: 
// Module Name: sensor
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


// Sensor Module with encoded states
module sensor(
    input wire sensor_west,         // Left sensor
    input wire sensor_east,         // Right sensor
    output reg [1:0] sensor_state   // Combined sensor state
);
    // Sensor State Encodings
    parameter NO_LINE      = 2'b11;     // Neither sensor detects line
    parameter LEFT_ONLY   = 2'b01;     // Only right sensor detects line
    parameter RIGHT_ONLY    = 2'b10;     // Only left sensor detects line
    parameter INTERSECTION = 2'b00;     // Both sensors detect line

    // Truth Table Implementation
    //-----------------------------
    // sensor_west | sensor_east | sensor_state
    //     0       |     0       |    NO_LINE
    //     0       |     1       |    RIGHT_ONLY
    //     1       |     0       |    LEFT_ONLY
    //     1       |     1       |    INTERSECTION
    //-----------------------------

    always @(sensor_west, sensor_east)
        case({sensor_west, sensor_east})
            2'b00   :   sensor_state = INTERSECTION;
            2'b01   :   sensor_state = LEFT_ONLY;
            2'b10   :   sensor_state = RIGHT_ONLY;
            2'b11   :   sensor_state = NO_LINE;
        endcase
endmodule
