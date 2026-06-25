module servo_controller(

    input clk,             // 100 MHz clock

    input rst,             // Active-high reset

    input prox1,           // Close trigger (from proximity sensor 1)

    input prox2,           // Open trigger (from proximity sensor 2)

    output reg pwm_out,    // PWM output to servo

    output reg servo_closed // Status output

);

 

    parameter CLK_FREQ = 100_000_000;

    parameter PWM_PERIOD = 2_000_000;  // 20ms period

   

    // Fast movement parameters

    parameter OPEN_POS = 200_000;    // 2ms (10%)

    parameter CLOSED_POS = 70_000;   // 0.7ms (3.5%)

   

    reg [31:0] pwm_counter = 0;

    reg [31:0] target_pos = OPEN_POS;

    reg servo_moving = 0;

 

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            pwm_counter <= 0;

            target_pos <= OPEN_POS;

            servo_closed <= 0;

        end

        else begin

            // Handle proximity sensor triggers

            if (~prox1) begin

                target_pos <= CLOSED_POS;

                servo_closed <= 1;

            end

            else if (~prox2) begin

                target_pos <= OPEN_POS;

                servo_closed <= 0;

            end

 

            // Direct position setting (no smooth transition)

            pwm_counter <= (pwm_counter < PWM_PERIOD-1) ? pwm_counter + 1 : 0;

            pwm_out <= (pwm_counter < target_pos) ? 1'b1 : 1'b0;

        end

    end

endmodule

 



 



 
