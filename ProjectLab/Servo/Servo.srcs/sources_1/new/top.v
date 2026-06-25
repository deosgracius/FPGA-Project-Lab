module top(
    input clk,          // 100 MHz clock
    input rst,        // Reset button
    input sensor1,      // Proximity sensor 1 (open)
    input sensor2,      // Proximity sensor 2 (close)
    output pwm          // PWM output to servo
);

// Synchronization registers for sensors
reg [1:0] sensor1_sync, sensor2_sync;

// Position register (0 = open, 1 = close)
reg position;

// Edge detection wires
wire sensor1_rise, sensor2_rise;

// Double-flop synchronizer
always @(posedge clk or posedge rst) begin
    if(rst) begin
        sensor1_sync <= 2'b00;
        sensor2_sync <= 2'b00;
    end
    else begin
        sensor1_sync <= {sensor1_sync[0], sensor1};
        sensor2_sync <= {sensor2_sync[0], sensor2};
    end
end

// Rising edge detection
assign sensor1_rise = (sensor1_sync == 2'b01);
assign sensor2_rise = (sensor2_sync == 2'b01);

// Position control logic
always @(posedge clk or posedge rst) begin
    if(rst) begin
        position <= 1'b0;  // Default to open position
    end
    else begin
        case({sensor2_rise, sensor1_rise})
            2'b10: position <= 1'b1;  // Close
            2'b01: position <= 1'b0;  // Open
            default: position <= position; // Maintain state
        endcase
    end
end

// Servo controller instantiation
servo servo_controller(
    .clk(clk),
    .rst(rst),
    .position(position),
    .pwm(pwm)
);
pwm_generator pwm_gen (
    .clk(clk),
    .rst(rst),
    .duty_cycle(duty_cycle),
    .pwm(pwm)
);

endmodule