`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2025 09:45:46 PM
// Design Name: 
// Module Name: top_module
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

`timescale 1ns / 1ps

 

module top(

    input clk,             // 100MHz (W5)

    //input rst,             // Center button (U18)

    //input ir_input,        // IR sensor (J15)

    input sensor_left,     // Active-low (V16)

    input sensor_right,    // Active-low (V17)

    input sensor_T,        // Active-low (V18)

    //input limit_switch,    // (H16)

    output enA, enB,       // Motor enables (always on)

    output in1, in2, in3, in4,  // Motor directions

    //output pwm_servo       // Servo control (G13)

);

 

    // System Parameters

    //parameter CLK_FREQ = 100_000_000;

   

    // Internal Signals

    wire [2:0] sensor_status;

    wire [1:0] motorL_state, motorR_state;

    wire use_pwm;

    wire [1:0] freq_out;

    wire ir_detected;

 

    // Module Instantiations

    sensor_module sensors(

        .clk(clk),

        .sensor_left(sensor_left),

        .sensor_right(sensor_right),

        .sensor_T(sensor_T),

        .sensor_status(sensor_status)

    );

 

    rover_control controller(

        .clk(clk),

        .rst(rst),

        //.ir_detected(freq_out != 2'b11),

        .sensor_status(sensor_status),

        .motorL_state(motorL_state),

        .motorR_state(motorR_state),

        .use_pwm(use_pwm)

    );

 

    motor_control motors(

        .clk(clk),

        .stateL(motorL_state),

        .stateR(motorR_state),

        .use_pwm(use_pwm),

        .enA(enA),

        .enB(enB),

        .in1(in1),

        .in2(in2),

        .in3(in3),

        .in4(in4)

    );

 

    ir_receiver ir(

        .clk(clk),

        .ir_input(ir_input),

        .freq_out(freq_out)

    );

 

    servo_controller servo(

        .clk(clk),

        .rst(rst),

        .sensor_status(sensor_status),

        .pwm_out(pwm_servo)

    );

 

endmodule

 

module rover_control(

    input clk,

    input rst,

    input ir_detected,

    input [2:0] sensor_status, // [left, right, T]

    output reg [1:0] motorL_state,

    output reg [1:0] motorR_state,

    output reg use_pwm

);

 

    // State Definitions

    typedef enum {

        IDLE, LINE_FOLLOW, RIGHT_TURN,

        LINE_LOST, REVERSE, LEFT_TURN

    } state_t;

   

    reg [2:0] state = IDLE;

    reg [27:0] timer = 0;

   

    // Timing Parameters

    parameter IDLE_TIMEOUT = 300_000_000; // 3 seconds

    parameter TURN_PWM = 150; // 60% duty cycle

   

    always @(posedge clk or posedge rst) begin

        if(rst) begin

            state <= IDLE;

            motorL_state <= 2'b00;

            motorR_state <= 2'b00;

            use_pwm <= 0;

            timer <= 0;

        end

        else begin

            case(state)

                IDLE: begin

                    motorL_state <= 2'b00;

                    motorR_state <= 2'b00;

                    use_pwm <= 0;

                    if(ir_detected) state <= LINE_FOLLOW;

                end

               

                LINE_FOLLOW: begin

                    use_pwm <= 0;

                    case(sensor_status[2:1])

                        2'b11: {motorL_state, motorR_state} <= {2'b01, 2'b01}; // Forward

                        2'b10: {motorL_state, motorR_state} <= {2'b01, 2'b00}; // Right adjust

                        2'b01: {motorL_state, motorR_state} <= {2'b00, 2'b01}; // Left adjust

                        default: begin

                            state <= LINE_LOST;

                            timer <= 0;

                        end

                    endcase

                   

                    if(sensor_status[0]) state <= RIGHT_TURN;

                end

               

                RIGHT_TURN: begin

                    use_pwm <= 1;

                    {motorL_state, motorR_state} <= {2'b01, 2'b10}; // Left FWD, Right REV

                    if(sensor_status[2:1] == 2'b11) begin

                        state <= LINE_FOLLOW;

                        use_pwm <= 0;

                    end

                end

               

                LINE_LOST: begin

                    {motorL_state, motorR_state} <= 2'b00;

                    if(timer < IDLE_TIMEOUT) timer <= timer + 1;

                    else begin

                        state <= REVERSE;

                        timer <= 0;

                    end

                end

               

                REVERSE: begin

                    use_pwm <= 0;

                    case(sensor_status[2:1])

                        2'b11: {motorL_state, motorR_state} <= {2'b10, 2'b10}; // Full reverse

                        2'b10: {motorL_state, motorR_state} <= {2'b10, 2'b00}; // Reverse right

                        2'b01: {motorL_state, motorR_state} <= {2'b00, 2'b10}; // Reverse left

                        default: {motorL_state, motorR_state} <= {2'b10, 2'b10};

                    endcase

                   

                    if(sensor_status[0]) state <= LEFT_TURN;

                end

               

                LEFT_TURN: begin

                    use_pwm <= 1;

                    {motorL_state, motorR_state} <= {2'b10, 2'b01}; // Right FWD, Left REV

                    if(sensor_status[2:1] == 2'b11) begin

                        state <= LINE_FOLLOW;

                        use_pwm <= 0;

                    end

                end

            endcase

        end

    end

endmodule

 

module motor_control(

    input clk,

    input [1:0] stateL,

    input [1:0] stateR,

    input use_pwm,

    output enA, enB,

    output in1, in2, in3, in4

);

 

    reg [7:0] pwm_counter = 0;

    wire pwm_signal = (pwm_counter < (use_pwm ? 150 : 255));

   

    // Always enable motors

    assign enA = 1'b1;

    assign enB = 1'b1;

   

    // PWM applied to direction pins

    assign in1 = (stateL == 2'b01) & pwm_signal; // Left forward

    assign in2 = (stateL == 2'b10) & pwm_signal; // Left reverse

    assign in3 = (stateR == 2'b10) & pwm_signal; // Right reverse

    assign in4 = (stateR == 2'b01) & pwm_signal; // Right forward

 

    always @(posedge clk) begin

        pwm_counter <= pwm_counter + 1;

    end

endmodule

 

module sensor_module(

    input clk,

    input sensor_left,

    input sensor_right,

    input sensor_T,

    output reg [2:0] sensor_status

);

 

    reg [2:0] sync[0:2];

    reg [19:0] db_counter[0:2];

   

    always @(posedge clk) begin

        // Synchronization

        sync[0] <= {~sensor_left, ~sensor_right, ~sensor_T};

        sync[1] <= sync[0];

        sync[2] <= sync[1];

       

        // Debounce logic

        for(integer i=0; i<3; i=i+1) begin

            if(sync[2][i] != sensor_status[i]) begin

                db_counter[i] <= 0;

            end

            else if(db_counter[i] < 1_000_000) begin

                db_counter[i] <= db_counter[i] + 1;

            end

            else begin

                sensor_status[i] <= sync[2][i];

            end

        end

    end

endmodule
