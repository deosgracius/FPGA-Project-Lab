`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/31/2025 09:23:10 AM
// Design Name: 
// Module Name: SM
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

module state_machine(
    input clk,
    input rst,
    input [1:0] sensor_out,  // Active-low sensors (0 = metal detected, 1 = no metal)
    input intersection,       
    output reg [1:0] stateL,  // Left motor state
    output reg [1:0] stateR,  // Right motor state
    output reg mission_complete
);

    // State Encoding
    parameter FORWARD   = 3'b001;
    parameter RIGHT    = 3'b010;
    parameter LEFT     = 3'b011;
    parameter REVERSE  = 3'b100;
    parameter STOP     = 3'b000;

    // Registers for tracking state and intersection count
    reg [2:0] current_state;
    reg [2:0] next_state;
    reg [2:0] intersection_count;
    reg intersection_processed;

    // Sequential Logic: Update State on Clock Edge
    always @(posedge clk) begin
        if (rst) begin
            current_state <= FORWARD;
            intersection_count <= 3'b000;
            mission_complete <= 1'b0;
            intersection_processed <= 1'b0;
        end
        if (!rst) begin
            current_state <= next_state;
            
            // Handle intersection counting with processed flag
            if (intersection && !intersection_processed && 
               (current_state == LEFT || current_state == RIGHT || current_state == FORWARD)) begin
                intersection_count <= intersection_count + 1'b1;
                intersection_processed <= 1'b1;
            end
            
            // Reset the processed flag when leaving intersection
            if (!intersection) begin
                intersection_processed <= 1'b0;
            end
        end
    end

    // Next State Logic using case and if
    always @(posedge clk) begin
        next_state = current_state;
        mission_complete = 1'b0;

        case (current_state)
            FORWARD: begin
                if (intersection) begin
                    next_state = STOP;
                end
            end

            STOP: begin
                if (intersection) begin
                    if (intersection_count == 3'b000) next_state = LEFT;     
                    if (intersection_count == 3'b001) next_state = RIGHT;    
                    if (intersection_count == 3'b010) next_state = FORWARD;  
                    if (intersection_count == 3'b011) next_state = REVERSE;  
                    if (intersection_count == 3'b100) begin
                        mission_complete = 1'b1;
                    end
                end
            end

            LEFT: begin
                if (!intersection) next_state = FORWARD;
            end

            RIGHT: begin
                if (!intersection) next_state = FORWARD;
            end

            REVERSE: begin
                if (intersection) next_state = STOP;
            end
        endcase
    end

    // Motor Output Logic
    always @(posedge clk) begin
        stateL = 2'b00;  // Default: Stop
        stateR = 2'b00;  // Default: Stop

        case (current_state)
            FORWARD: begin
                stateL = 2'b01;  // Forward
                stateR = 2'b01;  // Forward
                
                // Line following fixes
                if (sensor_out == 2'b01) begin  // Right sensor detects
                    stateR = 2'b01;  // Stop right motor
                    stateL = 2'b00;  // Left motor forward
                end
                if (sensor_out == 2'b10) begin  // Left sensor detects
                    stateL = 2'b01;  // Stop left motor
                    stateR = 2'b00 ;  // Right motor forward
                end
            end

            LEFT: begin
                stateL = 2'b10;  // Reverse left motor
                stateR = 2'b01;  // Forward right motor
            end

            RIGHT: begin
                stateL = 2'b01;  // Forward left motor
                stateR = 2'b10;  // Reverse right motor
            end

            REVERSE: begin
                stateL = 2'b10;  // Reverse
                stateR = 2'b10;  // Reverse
            end

            STOP: begin
                stateL = 2'b00;  // Stop
                stateR = 2'b00;  // Stop
            end
        endcase
    end

endmodule
