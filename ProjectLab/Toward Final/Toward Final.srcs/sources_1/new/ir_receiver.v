module ir_receiver (
    input clk,          // 100 MHz clock
    input ir_signal,     // IR sensor input
    output reg [1:0] HZ  // 00=invalid, 01=1kHz, 10=2kHz, 11=3kHz
);

    // Synchronize IR input to prevent metastability
    reg [1:0] ir_sync;
    reg ir_prev;

    always @(posedge clk) begin
        ir_sync <= {ir_sync[0], ir_signal};
        ir_prev <= ir_sync[1];
    end

    // Detect rising edges
    wire ir_rise = ~ir_prev & ir_sync[1];

    // 10 ms timer (1,000,000 cycles at 100 MHz)
    reg [19:0] timer_counter;
    wire timer_pulse = (timer_counter == 20'd999_999);

    // Edge counter
    reg [15:0] edge_counter;
    reg [15:0] latched_count;

    // Counters for frequency detection
    reg [7:0] count0 = 0; // Invalid
    reg [7:0] count1 = 0; // 1kHz
    reg [7:0] count2 = 0; // 2kHz
    reg [7:0] count3 = 0; // 3kHz
    reg [7:0] sec2 = 0;   // Counts to 200 (2 seconds)

    // Timer and edge counting logic
    always @(posedge clk) begin
        // Timer logic
        if (timer_pulse) begin
            timer_counter <= 0;
        end else begin
            timer_counter <= timer_counter + 1;
        end

        // Edge counter logic
        if (timer_pulse) begin
            edge_counter <= 0;
        end else if (ir_rise) begin
            edge_counter <= edge_counter + 1;
        end

        // Latch the edge count at the end of each 10 ms period
        if (timer_pulse) begin
            latched_count <= edge_counter;
        end
    end

    // Frequency detection and output logic
    always @(posedge clk) begin
        if (timer_pulse) begin
            if (sec2 < 200) begin
                sec2 <= sec2 + 1;
                // Count frequencies based on edge count
                case (latched_count)
                    19, 20, 21:    count1 <= count1 + 1; // 1kHz (~20 edges)
                    39, 40, 41:    count2 <= count2 + 1; // 2kHz (~40 edges)
                    59, 60, 61:    count3 <= count3 + 1; // 3kHz (~60 edges)
                    default:       count0 <= count0 + 1; // Invalid
                endcase
            end else begin
                // After 2 seconds (200 periods), evaluate predominant frequency
                if (count0 > count1 && count0 > count2 && count0 > count3) begin
                    HZ <= 2'b00; // Invalid
                    // Reset only if invalid count is greatest
                    sec2 <= 0;
                    count0 <= 0;
                    count1 <= 0;
                    count2 <= 0;
                    count3 <= 0;
                end else if (count1 > count0 && count1 > count2 && count1 > count3) begin
                    HZ <= 2'b01; // 1kHz
                    // No reset here
                end else if (count2 > count0 && count2 > count1 && count2 > count3) begin
                    HZ <= 2'b10; // 2kHz
                    // No reset here
                end else if (count3 > count0 && count3 > count1 && count3 > count2) begin
                    HZ <= 2'b11; // 3kHz
                    // No reset here
                end
            end
        end
    end

endmodule 