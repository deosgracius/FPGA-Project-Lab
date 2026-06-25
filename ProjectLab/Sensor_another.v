// Second method (using AND operators)
module sensor_behavior_and(
    input wire sensor_west,         // Left sensor
    input wire sensor_east,         // Right sensor
    output reg [1:0] sensor_state   // Combined sensor state
);
    always @(sensor_west, sensor_east) begin
        // No line detected (neither sensor)
        if (sensor_west == 0 && sensor_east == 0)
            sensor_state = 2'b00;
            
        // Right sensor only
        if (sensor_west == 0 && sensor_east == 1)
            sensor_state = 2'b01;
            
        // Left sensor only
        if (sensor_west == 1 && sensor_east == 0)
            sensor_state = 2'b10;
            
        // Both sensors (intersection)
        if (sensor_west == 1 && sensor_east == 1)
            sensor_state = 2'b11;
    end
endmodule