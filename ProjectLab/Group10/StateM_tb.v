`include "state_m.v"

module state_m_tb;

    // Testbench signals
    reg clk;
    reg [3:0] location;
    wire [1:0] motorcontrol;

    // Instantiate the module under test
    state_m uut (
        .clk(clk),
        .location(location),
        .motorcontrol(motorcontrol)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle clock every 5 time units
    end

    // Testbench process
    initial begin
        // Initialize inputs
        location = 4'b0000;
        #10;

        // Test case 1: location = 4'b1111
        location = 4'b1111;
        #20;
        $display("motorcontrol: %b (expected: 00)", motorcontrol);

        // Test case 2: location = 4'b1011
        location = 4'b1011;
        #20;
        $display("motorcontrol: %b (expected: 01)", motorcontrol);

        // Test case 3: location = 4'b1110
        location = 4'b1110;
        #20;
        $display("motorcontrol: %b (expected: 11)", motorcontrol);

        // Test case 4: location = 4'b0000 (default state)
        location = 4'b0000;
        #20;
        $display("motorcontrol: %b (expected: 00)", motorcontrol);

        // Finish simulation
        $finish;
    end

    // Waveform trace generation
    initial begin
        $dumpfile("state_m_waveform.vcd"); // Specify the name of the output file
        $dumpvars(0, state_m_tb);          // Dump all variables in the state_m_tb module
    end

endmodule

