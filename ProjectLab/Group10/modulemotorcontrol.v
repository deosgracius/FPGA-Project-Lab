module motorcontrol (

    input clk,

    input reg [1:0] motorcontrol,

    output enA, enB,

    output reg [1:0] MotorL,

    output reg [1:0] MotorR

);

 

    assign enA = 1'b1;

    assign enB = 1'b1;

 

    // Motor Control Definitions

    parameter MOVE_FORWARD  = 2'b00; 

    parameter TURN_LEFT     = 2'b01; 

    parameter TURN_RIGHT    = 2'b11; 

 

    // Motor State Definitions

    parameter M1_FORWARD   = 2'b01;

    parameter M1_STOP      = 2'b11;

    parameter M2_FORWARD   = 2'b01;

    parameter M2_STOP      = 2'b11;

 

    // Edge-triggered motor control logic

    always @(posedge clk) begin

        case (motorcontrol)

            MOVE_FORWARD: begin

                MotorL <= M1_FORWARD;

                MotorR <= M2_FORWARD;

            end

            TURN_LEFT: begin

                MotorL <= M1_STOP;

                MotorR <= M2_FORWARD;

            end

            TURN_RIGHT: begin

                MotorL <= M1_FORWARD;

                MotorR <= M2_STOP;

            end

            default: begin

                MotorL <= M1_STOP;

                MotorR <= M2_STOP;
            end

        endcase

    end

 

endmodule
