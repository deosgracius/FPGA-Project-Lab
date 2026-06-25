module servo_controller (
    input clk,
    input rst,
    input prox1,
    input prox2,
    output reg pwm_out,
    output reg servo_closed,
    output reg mosfet,
    input prox3,
    output reg done, // Added as output
    output reg TD
);
    parameter CLK_FREQ = 100_000_000;
    parameter PWM_PERIOD = 2_000_000;
    parameter OPEN_POS = 220_000;
    parameter CLOSED_POS = 70_000;

    reg [31:0] pwm_counter = 0;
    reg [31:0] target_pos = OPEN_POS;
    reg tstart = 0;
    reg [27:0] timer = 0;
    reg [27:0] timer1 = 0;
    reg TS = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_counter <= 0;
            target_pos <= OPEN_POS;
            servo_closed <= 0;
            tstart <= 0;
            timer <= 0;
            done <= 0;
            mosfet <= 0;
            pwm_out <= 0;
            timer1 <= 0;
            TD <= 0;
            TS <= 0;
        end else begin
            if (~prox1) begin
                target_pos <= CLOSED_POS;
                servo_closed <= 1;
                if (!tstart) begin
                    tstart <= 1;
                    timer <= 0;
                end
            end else if (~prox2 && ~prox3) begin
                TS = 1;
                target_pos <= OPEN_POS;
                servo_closed <= 0;
            end
            
            if (TS == 1) begin
                if (timer1 < 100_000_000) begin
                    timer1 <= timer1 + 1;
                end else begin
                    TD <= 1;
                    target_pos <= OPEN_POS;
                    servo_closed <= 0;
                end
            end
            
            if (tstart) begin
                if (timer < 200_000_000) begin
                    timer <= timer + 1;
                end else begin
                    done <= 1;
                end
            end

            if (done && prox3) begin
                mosfet <= 1;
            end else begin
                mosfet <= 0;
            end

            pwm_counter <= (pwm_counter < PWM_PERIOD-1) ? pwm_counter + 1 : 0;
            pwm_out <= (pwm_counter < target_pos) ? 1'b1 : 1'b0;
        end
    end
endmodule