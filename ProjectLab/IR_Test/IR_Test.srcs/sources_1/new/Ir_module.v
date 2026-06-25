module ir_receiver (
    input clk,          // 100 MHz clock
    input ir_input,     // IR sensor input
    output reg [1:0] freq_out  // 00=1kHz, 01=2kHz, 10=3kHz, 11=invalid
);

    // Synchronize the IR input to avoid metastability
    reg [1:0] ir_sync;
    reg ir_prev;
    always @(posedge clk) begin
        ir_sync <= {ir_sync[0], ir_input};
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

        // Latch the count at the end of the period
        if (timer_pulse) begin
            latched_count <= edge_counter;
        end
    end

    // Frequency decoder with adjusted ranges
    always @(posedge clk) begin
        if (timer_pulse) begin
            case (latched_count)
                19, 20, 21:    freq_out <= 2'b00; // 1 kHz (~10 edges)
                39,40,41   :   freq_out <= 2'b01; // 2 kHz (~20 edges)
                59, 60, 61:   freq_out <= 2'b10; // 3 kHz (~30 edges)
                default:      freq_out <= 2'b11; // Invalid
            endcase
        end
    end

endmodule