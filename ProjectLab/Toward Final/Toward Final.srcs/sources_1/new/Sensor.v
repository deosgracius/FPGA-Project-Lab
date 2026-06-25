module sensor_module(

    input sensor_left,     

    input sensor_right,    

    input sensor_T,         // T-intersection sensor (active low)

    output reg [2:0] sensor_status // [left, right, T] (active high)

);

    always @(*) begin

        sensor_status[2] = ~sensor_left;    // Convert to active high

        sensor_status[1] = ~sensor_right;

        sensor_status[0] = ~sensor_T;

    end

endmodule