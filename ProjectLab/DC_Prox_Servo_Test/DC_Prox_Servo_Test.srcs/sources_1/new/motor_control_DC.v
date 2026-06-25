`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2025 10:08:27 PM
// Design Name: 
// Module Name: motor_control_DC
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

    input start_lift,      // From servo_closed

    input limit_switch,    // Active-high limit switch

    output reg mosfet      // Motor control

);

 

    reg [27:0] timer;      // 28 bits for 200,000,000 cycles (2 sec)

    reg lifting;

    reg start_lift_prev;   // For edge detection

 

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            mosfet <= 0;

            timer <= 0;

            lifting <= 0;

            start_lift_prev <= 0;

        end

        else begin

            start_lift_prev <= start_lift;  // Store previous value

           

            // Detect rising edge of servo_closed

            if (!lifting && start_lift && !start_lift_prev) begin

                lifting <= 1;

                timer <= 0;

            end

           

            if (lifting) begin

                if (limit_switch) begin  // Stop motor when limit reached

                    mosfet <= 0;

                    lifting <= 0;

                end

                else if (timer < 200_000_000) begin  // 2 second delay

                    timer <= timer + 1;

                    mosfet <= 0;  // Waiting period

                end

                else begin

                    mosfet <= 1;  // Activate motor

                end

            end

        end

    end

endmodule