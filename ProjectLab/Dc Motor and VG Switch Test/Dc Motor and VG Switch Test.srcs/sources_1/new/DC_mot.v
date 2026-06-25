`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2025 07:00:03 PM
// Design Name: 
// Module Name: DC_mot
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


module motor_control(

    input clk,

    input rst,

    input start_lift,      // Signal from servo closure

    input limit_switch,    // Physical limit switch

    output reg mosfet      // Motor control signal

);

 

    reg [27:0] timer;      // 100MHz clock -> 27 bits for 2 seconds

    reg lifting = 0;

 

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            mosfet <= 0;

            timer <= 0;

            lifting <= 0;

        end

        else begin

            if (start_lift && !lifting) begin

                lifting <= 1;

                timer <= 0;

            end

           

            if (lifting) begin

                if (limit_switch) begin

                    mosfet <= 0;

                    lifting <= 0;

                end

                else begin

                    // Wait 2 seconds before activating

                    if (timer < 200_000_000) begin  // 2 seconds

                        timer <= timer + 1;

                        mosfet <= 0;

                    end

                    else begin

                        mosfet <= 1;

                    end

                end

            end

        end

    end

endmodule