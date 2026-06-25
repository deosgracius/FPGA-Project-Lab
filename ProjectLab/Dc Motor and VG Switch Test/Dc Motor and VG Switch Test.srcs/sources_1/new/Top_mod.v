module top(

    input clk,             // 100 MHz (W5)

    //input rst,             // Center button (U18)

    input prox1,           // Proximity sensor 1 (J15)

    input prox2,           // Proximity sensor 2 (L16)

    input limit_switch,    // Physical limit (V17)

    output pwm_servo,      // Servo control (G13)

    output mosfet          // Motor control (H15)

);

 

    wire servo_closed;

 

    // Debounce inputs

    wire clean_prox1, clean_prox2, clean_limit;

    debounce db1(clk, prox1, clean_prox1);

    debounce db2(clk, prox2, clean_prox2);

    debounce db3(clk, limit_switch, clean_limit);

 

    servo_controller servo(

        .clk(clk),

        .prox1(clean_prox1),

        .prox2(clean_prox2),

        .pwm_out(pwm_servo),

        .servo_closed(servo_closed)

    );

 

    motor_control motor(

        .clk(clk),

        .start_lift(servo_closed),

        .limit_switch(clean_limit),

        .mosfet(mosfet)

    );

 

endmodule

 

// Debounce Module

module debounce(

    input clk,

    input noisy,

    output reg clean

);

    reg [19:0] count;

    reg new;

 

    always @(posedge clk) begin

        if (noisy != new) begin

            new <= noisy;

            count <= 0;

        end

        else if (count < 1_000_000)  // 10ms debounce

            count <= count + 1;

        else

            clean <= new;

    end

endmodule