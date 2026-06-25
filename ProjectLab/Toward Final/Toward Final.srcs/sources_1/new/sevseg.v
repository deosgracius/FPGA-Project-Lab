module seven_seg_decoder (
    input [3:0] digit,
    output reg [6:0] seg
);
    always @(*) begin
        case (digit)
            4'd0: seg = 7'b1000000; // 0: a, b, c, d, e, f ON (0), g OFF (1)
            4'd1: seg = 7'b1111001; // 1: b, c ON (0), others OFF (1)
            4'd2: seg = 7'b0100100; // 2: a, b, d, e, g ON (0)
            4'd3: seg = 7'b0110000; // 3: a, b, c, d, g ON (0)
            4'd4: seg = 7'b0011001; // 4: b, c, f, g ON (0)
            4'd5: seg = 7'b0010010; // 5: a, c, d, f, g ON (0)
            4'd6: seg = 7'b0000010; // 6: a, c, d, e, f, g ON (0)
            4'd7: seg = 7'b1111000; // 7: a, b, c ON (0)
            4'd8: seg = 7'b0000000; // 8: all segments ON (0)
            4'd9: seg = 7'b0010000; // 9: a, b, c, d, f, g ON (0)
            default: seg = 7'b1111111; // All segments OFF (1)
        endcase
    end
endmodule


