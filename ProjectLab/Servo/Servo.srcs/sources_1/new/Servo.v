module servo(
    input clk,
    input rst,
    input position,      // 0 = open (2%), 1 = close (7%)
    output pwm
);

reg [17:0] duty_cycle;

// PWM Generator instantiation


// Duty cycle selection based on position
always @(*) begin
    case(position)
        1'b0: duty_cycle = 18'd40000;    // 2% duty cycle (open)
        1'b1: duty_cycle = 18'd140000;   // 7% duty cycle (close)
    endcase
end

endmodule

