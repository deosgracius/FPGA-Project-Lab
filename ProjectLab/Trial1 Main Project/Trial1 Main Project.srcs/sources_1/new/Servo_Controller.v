`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2025 10:04:15 PM
// Design Name: 
// Module Name: Servo_Controller
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


// Servo Controller with Auto-Shutdown

module servo_controller(

    input clk,

    input rst,

    input start,

    output reg pwm_out,

    output reg done

);

 

parameter CLK_FREQ = 100_000_000;

parameter INIT_DUTY = 10_000_000; // 10% (2ms)

parameter TARGET_DUTY = 3_500_000; // 3.5% (0.7ms)

parameter STEP = 50_000;

 

reg [31:0] counter;

reg [31:0] current_duty;

reg [31:0] movement_counter;

 

always @(posedge clk or posedge rst) begin

    if (rst) begin

        counter <= 0;

        current_duty <= INIT_DUTY;

        pwm_out <= 0;

        done <= 0;

        movement_counter <= 0;

    end else if (start) begin

        // PWM Generation

        counter <= (counter < 20_000_000) ? counter + 1 : 0; // 20ms period

        pwm_out <= (counter < current_duty) ? 1'b1 : 1'b0;

       

        // Movement logic

        if (movement_counter < 500_000) begin // Update every 5ms

            movement_counter <= movement_counter + 1;

        end else begin

            movement_counter <= 0;

            if (current_duty > TARGET_DUTY) begin

                current_duty <= current_duty - STEP;

                done <= 0;

            end else begin
                done <= 1;
                pwm_out <= 0; // Complete shutdown

            end

        end

    end else begin
        current_duty <= INIT_DUTY;
        done <= 0;
        pwm_out <= 0;

    end

end

endmodule
