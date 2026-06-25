module state_machine(
    input clk,
    input rst,
    input [1:0] sensor_out,  // Active-low sensors (0 = metal detected, 1 = no metal)
    input intersection,       
    output reg [1:0] stateL,  // Left motor state
    output reg [1:0] stateR   // Right motor state
);
    // State Encoding
    parameter FORWARD  = 3'b001;
    parameter RIGHT    = 3'b010;
    parameter LEFT     = 3'b011;
    parameter REVERSE  = 3'b100;
    parameter STOP     = 3'b000;
    
    // Registers for tracking state and intersection count
    reg [2:0] current_state;
    reg [2:0] next_state;
    reg [2:0] intersection_count;
    reg intersection_processed;  // Flag to handle intersection detection

    // Sequential Logic: Update State on Clock Edge
    always @(posedge clk) begin
        if (rst) begin
            current_state <= FORWARD;
            intersection_count <= 3'b000;
            intersection_processed <= 1'b0;
        end 
        if (!rst) begin
            current_state <= next_state;
            
            // Handle intersection counting
            if (intersection && !intersection_processed && current_state == FORWARD) begin
                intersection_count <= intersection_count + 1'b1;
                intersection_processed <= 1'b1;
            end 
            if (!intersection) begin
                intersection_processed <= 1'b0;
            end
        end
    end

    // Next State Logic using case and if statements
    always @(posedge clk) begin
        next_state = current_state;  // Default: stay in current state
        
        case (current_state)
            FORWARD: begin
                if (intersection && !intersection_processed) begin
                    if (intersection_count == 3'b000) next_state = LEFT;     
                    if (intersection_count == 3'b001) next_state = RIGHT;    
                    if (intersection_count == 3'b010) next_state = FORWARD;  
                    if (intersection_count == 3'b011) next_state = REVERSE;  
                    if (intersection_count == 3'b100) next_state = STOP;    
                end
            end
            
            LEFT: begin
                if (!intersection) begin  // Wait until we clear the intersection
                    if (sensor_out == 2'b01) next_state = FORWARD;  
                end
            end
            
            RIGHT: begin
                if (!intersection) begin  // Wait until we clear the intersection
                    if (sensor_out == 2'b10) next_state = FORWARD;  
                end
            end
            
            REVERSE: begin
                if (intersection && !intersection_processed) next_state = STOP;
            end
            
            STOP: begin
                next_state = STOP;  // Stay stopped
            end
        endcase
    end

    // Motor Output Logic
    always @(posedge clk) begin
        stateL = 2'b00;  // Default: Stop
        stateR = 2'b00;  // Default: Stop

        case (current_state)
            FORWARD: begin
                case (sensor_out)
                    2'b00: begin  // Both sensors on line
                        stateL = 2'b01;  // Forward
                        stateR = 2'b01;  // Forward
                    end
                    2'b10: begin  // Left sensor on line
                        stateL = 2'b10;  // Backward
                        stateR = 2'b01;  // Forward
                    end
                    2'b01: begin  // Right sensor on line
                        stateL = 2'b01;  // Forward
                        stateR = 2'b10;  // Backward
                    end
                    2'b11: begin  // No sensors on line
                        stateL = 2'b01;  // Forward
                        stateR = 2'b01;  // Forward
                    end
                endcase
            end
            
            LEFT: begin
                stateL = 2'b10;  // Backward
                stateR = 2'b01;  // Forward
            end
            
            RIGHT: begin
                stateL = 2'b01;  // Forward
                stateR = 2'b10;  // Backward
            end
            
            REVERSE: begin
                stateL = 2'b10;  // Backward
                stateR = 2'b10;  // Backward
            end
            
            STOP: begin
                stateL = 2'b00;  // Stop
                stateR = 2'b00;  // Stop
            end
        endcase
    end
endmodule