// PWM Generator Module
module pwm_generator(
    input clk,
    input rst,
    input [17:0] duty_cycle,
    output reg pwm
);

reg [20:0] counter;
localparam PERIOD = 21'd1999999;  // 20ms period (50Hz)

always @(posedge clk or posedge rst) begin
    if(rst) begin
        counter <= 21'd0;
        pwm <= 1'b0;
    end
    else begin
        if(counter == PERIOD)
            counter <= 21'd0;
        else
            counter <= counter + 1;
            
        pwm <= (counter < duty_cycle);
    end
end

endmodule