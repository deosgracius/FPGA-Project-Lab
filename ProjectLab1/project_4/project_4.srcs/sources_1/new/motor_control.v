`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/30/2025 12:27:04 AM
// Design Name: 
// Module Name: motor_control
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


// Motor Control Module with encoded control signals
module motor_control(
    // Control outputs
    output reg In1,              
    output reg In2,              
    output reg In3,              
    output reg In4,              
    output wire enA,             
    output wire enB,             
    
    // Motor control inputs
    input wire [1:0] motor1_control,    // Motor 1: {In1,In3}
    input wire [1:0] motor2_control     // Motor 2: {In2,In4}
);
    // Motors always enabled
    assign enA = 1'b1;
    assign enB = 1'b1;

    // Motor State Encodings
    parameter M1_FWD = 2'b01;    // Motor 1 Forward: In1=0, In2=0
    parameter M1_REV = 2'b10;    // Motor 1 Reverse: In1=1, In2=1
    //parameter M1_OFF = 2'b10;    // Motor 1 Stop:    In1=1, In2=0

    //parameter M2_FWD = 2'b01;    // Motor 2 Forward: In2=0, In4=1
    //parameter M2_REV = 2'b10;    // Motor 2 Reverse: In2=1, In4=0
    //parameter M2_OFF = 2'b11;    // Motor 2 Stop:    In2=1, In4=1

    // Control logic for Motor 1
    always @(motor1_control) begin
        case(motor1_control)
            M1_FWD: begin    // Forward
                In1 = 1'b0;
                In2 = 1'b0;
            end
            M1_REV: begin    // Reverse
                In1 = 1'b1;
                In2 = 1'b1;
            end
            //M1_OFF: begin    // Stop
                //In1 = 1'b1;
                //In3 = 1'b0;
            //end
            default: begin   // Default to stop
                In1 = 1'b1;
                In2 = 1'b1;
            end
        endcase
    end

    // Control logic for Motor 2
    //always @(motor2_control) begin
        //case(motor2_control)
            //M2_FWD: begin    // Forward
                //In2 = 1'b0;
                //In4 = 1'b1;
            //end
          //  M2_REV: begin    // Reverse
              //  In2 = 1'b1;
               // In4 = 1'b0;
            //end
            //M2_OFF: begin    // Stop
               // In2 = 1'b1;
                //In4 = 1'b1;
            //end
            //default: begin   // Default to stop
               // In2 = 1'b1;
               // In4 = 1'b1;
            //end
       // endcase
    //end

endmodule
