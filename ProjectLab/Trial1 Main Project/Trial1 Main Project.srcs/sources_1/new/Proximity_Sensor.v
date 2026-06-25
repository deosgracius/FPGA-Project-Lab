`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2025 10:01:48 PM
// Design Name: 
// Module Name: Proximity_Sensor
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


// Proximity Sensor Detector

module proximity_sensor(

    input clk,

    input rst,

    input sensor_in,

    output reg detected

);

 

reg [23:0] debounce_counter;

reg sensor_sync;

 

always @(posedge clk) begin

    if (rst) begin

        detected <= 0;

        debounce_counter <= 0;

        sensor_sync <= 0;

    end else begin

        sensor_sync <= sensor_in;

        if (sensor_sync != detected) begin

            if (debounce_counter > 1_000_000) begin // 10ms debounce @ 100MHz

                detected <= sensor_sync;

                debounce_counter <= 0;

            end

            else debounce_counter <= debounce_counter + 1;

        end

        else debounce_counter <= 0;

    end

end

endmodule