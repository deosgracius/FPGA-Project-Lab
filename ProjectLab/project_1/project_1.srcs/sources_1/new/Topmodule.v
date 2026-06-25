// Top Module with State Control

module motor_system_top(

    input clk,              // W5

    input rst_n,            // U16 (BTNU)

    input proximity_in,     // V17 (IR Sensor)

    input emergency_btn,    // U18 (V10G5 1C24K)

    output servo_pwm,       // A14 (PMOD JA1)

    output dc_motor_pwm     // A16 (PMOD JA2)

);

 

wire rst = ~rst_n;

wire sensor_detected;

wire servo_done;

wire emergency_stop;

 

reg dc_motor_en;

reg [1:0] state;

 

// Debouncer for emergency stop

reg [19:0] emergency_counter;

always @(posedge clk) begin

    if (rst) emergency_counter <= 0;

    else emergency_counter <= emergency_btn ?

         (emergency_counter < 20'hFFFFF ? emergency_counter + 1 : 20'hFFFFF) : 0;

end

assign emergency_stop = (emergency_counter > 100000); // 1ms debounce

 

proximity_sensor sensor(

    .clk(clk),

    .rst(rst),

    .sensor_in(proximity_in),

    .detected(sensor_detected)

);

 

servo_controller servo(

    .clk(clk),

    .rst(rst),

    .start(sensor_detected),

    .pwm_out(servo_pwm),

    .done(servo_done)

);

 

dc_motor_controller motor(

    .clk(clk),

    .rst(rst),

    .enable(dc_motor_en),

    .emergency_stop(emergency_stop),

    .pwm_out(dc_motor_pwm)

);

 

// State Machine

localparam IDLE = 2'b00;

localparam SERVO_ACTIVE = 2'b01;

localparam LIFTING = 2'b10;

 

always @(posedge clk or posedge rst) begin

    if (rst) begin

        state <= IDLE;

        dc_motor_en <= 0;

    end else begin

        case(state)

            IDLE: begin

                if (sensor_detected) state <= SERVO_ACTIVE;

                dc_motor_en <= 0;

            end

           

            SERVO_ACTIVE: begin

                if (servo_done) begin

                    state <= LIFTING;

                    dc_motor_en <= 1;

                end

            end

           

            LIFTING: begin

                if (emergency_stop) begin

                    state <= IDLE;

                    dc_motor_en <= 0;

                end

            end

           

            default: state <= IDLE;

        endcase

    end

end

endmodule
