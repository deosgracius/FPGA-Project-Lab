`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/27/2025 11:24:12 AM
// Design Name: 
// Module Name: DC_Motor
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


 

// DC Motor Controller (original module)
module servo_controller(

    input clk,             // 100 MHz clock

    input rst,             // Active-high reset

    input prox1,           // Close trigger (active low)

    output reg pwm_out,    // PWM output to servo

    output reg servo_closed // Status output (1 = closed)

);

 

    parameter CLK_FREQ = 100_000_000;  // 100 MHz clock

    parameter PWM_PERIOD = 2_000_000;  // 20ms PWM period (2,000,000 cycles)

   

    // Servo position parameters

    parameter OPEN_POS  = 200_000;     // 2ms pulse width (open position)

    parameter CLOSED_POS = 70_000;     // 0.7ms pulse width (closed position)

   

    reg [31:0] pwm_counter;

    reg [31:0] target_pos;

   

    // State machine states

    reg [1:0] state;

    localparam IDLE    = 2'b00;

    localparam CLOSING = 2'b01;

    localparam CLOSED  = 2'b10;

   

    // Closing duration timer (1 second)

    reg [26:0] close_timer;  // 27 bits for 100,000,000 cycles (1 sec)

 

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state <= IDLE;

            pwm_counter <= 0;

            target_pos <= OPEN_POS;

            servo_closed <= 0;

            close_timer <= 0;

        end

        else begin

            case (state)

                IDLE: begin

                    if (~prox1) begin  // Detect block (active low)

                        state <= CLOSING;

                        target_pos <= CLOSED_POS;

                        close_timer <= 0;

                    end

                    else begin

                        target_pos <= OPEN_POS;  // Maintain open position

                    end

                    servo_closed <= 0;

                end

               

                CLOSING: begin

                    if (close_timer < CLK_FREQ-1) begin

                        close_timer <= close_timer + 1;  // 1 second timer

                    end

                    else begin

                        state <= CLOSED;

                        target_pos <= 0;  // Stop PWM after closing

                    end

                end

               

                CLOSED: begin

                    target_pos <= 0;  // Disable PWM output

                    servo_closed <= 1;  // Signal to motor controller

                    // Stay closed until reset

                end

            endcase

           

            // PWM generation logic

            if (target_pos > 0) begin

                pwm_counter <= (pwm_counter < PWM_PERIOD-1) ? pwm_counter + 1 : 0;

                pwm_out <= (pwm_counter < target_pos);

            end

            else begin

                pwm_counter <= 0;

                pwm_out <= 0;  // Disable PWM when target_pos = 0

            end

        end

    end

endmodule

 

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
