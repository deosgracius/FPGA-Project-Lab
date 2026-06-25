// add.v - Addition operation
module add(
    input [7:0] a,
    input [7:0] b,
    output [7:0] result
);
    assign result = a + b;
endmodule

// subtract.v - Subtraction operation
module subtract(
    input [7:0] a,
    input [7:0] b,
    output [7:0] result
);
    assign result = a - b;
endmodule

// and_op.v - AND operation
module and_op(
    input [7:0] a,
    input [7:0] b,
    output [7:0] result
);
    assign result = a & b;
endmodule

// or_op.v - OR operation
module or_op(
    input [7:0] a,
    input [7:0] b,
    output [7:0] result
);
    assign result = a | b;
endmodule

// xor_op.v - XOR operation
module xor_op(
    input [7:0] a,
    input [7:0] b,
    output [7:0] result
);
    assign result = a ^ b;
endmodule

// invert.v - INVERT operation
module invert(
    input [7:0] a,
    input [7:0] b,  // Not used, but included for consistent interface
    output [7:0] result
);
    assign result = ~a;
endmodule

// shift_left.v - Shift Left operation
module shift_left(
    input [7:0] a,
    input [7:0] b,  // b[2:0] determines shift amount
    output [7:0] result
);
    assign result = a << b[2:0];
endmodule

// shift_right.v - Shift Right operation
module shift_right(
    input [7:0] a,
    input [7:0] b,  // b[2:0] determines shift amount
    output [7:0] result
);
    assign result = a >> b[2:0];
endmodule

// mux_8to1.v - 8-to-1 Multiplexer
module mux_8to1(
    input [7:0] in0,  // Addition
    input [7:0] in1,  // Subtraction
    input [7:0] in2,  // AND
    input [7:0] in3,  // OR
    input [7:0] in4,  // XOR
    input [7:0] in5,  // INVERT
    input [7:0] in6,  // Shift Left
    input [7:0] in7,  // Shift Right
    input [2:0] select,
    output reg [7:0] out
);
    always @(*) begin
        case(select)
            3'b000: out = in0;  // Addition
            3'b001: out = in1;  // Subtraction
            3'b010: out = in2;  // AND
            3'b011: out = in3;  // OR
            3'b100: out = in4;  // XOR
            3'b101: out = in5;  // INVERT
            3'b110: out = in6;  // Shift Left
            3'b111: out = in7;  // Shift Right
            default: out = 8'b0;
        endcase
    end
endmodule

// alu_top.v - Top-level ALU module
module alu_top(
    input [7:0] opA,
    input [7:0] opB,
    input [2:0] opS,
    output [7:0] Result
);
    // Wires to connect modules
    wire [7:0] add_result;
    wire [7:0] sub_result;
    wire [7:0] and_result;
    wire [7:0] or_result;
    wire [7:0] xor_result;
    wire [7:0] invert_result;
    wire [7:0] shift_left_result;
    wire [7:0] shift_right_result;
    
    // Instantiate all operation modules
    add add_op (
        .a(opA),
        .b(opB),
        .result(add_result)
    );
    
    subtract sub_op (
        .a(opA),
        .b(opB),
        .result(sub_result)
    );
    
    and_op and_operation (
        .a(opA),
        .b(opB),
        .result(and_result)
    );
    
    or_op or_operation (
        .a(opA),
        .b(opB),
        .result(or_result)
    );
    
    xor_op xor_operation (
        .a(opA),
        .b(opB),
        .result(xor_result)
    );
    
    invert invert_op (
        .a(opA),
        .b(opB),  // Not used
        .result(invert_result)
    );
    
    shift_left shift_left_op (
        .a(opA),
        .b(opB),
        .result(shift_left_result)
    );
    
    shift_right shift_right_op (
        .a(opA),
        .b(opB),
        .result(shift_right_result)
    );
    
    // Instantiate multiplexer to select the output
    mux_8to1 result_mux (
        .in0(add_result),
        .in1(sub_result),
        .in2(and_result),
        .in3(or_result),
        .in4(xor_result),
        .in5(invert_result),
        .in6(shift_left_result),
        .in7(shift_right_result),
        .select(opS),
        .out(Result)
    );
endmodule

// add_tb.v - Testbench for Addition module
module add_tb;
    // Inputs
    reg [7:0] a;
    reg [7:0] b;
    
    // Outputs
    wire [7:0] result;
    
    // Instantiate the Unit Under Test (UUT)
    add uut (
        .a(a),
        .b(b),
        .result(result)
    );
    
    initial begin
        // Initialize inputs
        a = 0;
        b = 0;
        
        // Wait for global reset
        #100;
        
        // Test case 1: 5 + 10 = 15
        a = 8'd5;
        b = 8'd10;
        #10;
        if (result !== 8'd15) $display("Test case 1 failed: %d + %d = %d", a, b, result);
        else $display("Test case 1 passed");
        
        // Test case 2: 255 + 1 = 0 (overflow)
        a = 8'd255;
        b = 8'd1;
        #10;
        if (result !== 8'd0) $display("Test case 2 failed: %d + %d = %d", a, b, result);
        else $display("Test case 2 passed");
        
        // Test case 3: 128 + 128 = 0 (overflow)
        a = 8'd128;
        b = 8'd128;
        #10;
        if (result !== 8'd0) $display("Test case 3 failed: %d + %d = %d", a, b, result);
        else $display("Test case 3 passed");
        
        $finish;
    end
endmodule

// subtract_tb.v - Testbench for Subtraction module
module subtract_tb;
    // Inputs
    reg [7:0] a;
    reg [7:0] b;
    
    // Outputs
    wire [7:0] result;
    
    // Instantiate the Unit Under Test (UUT)
    subtract uut (
        .a(a),
        .b(b),
        .result(result)
    );
    
    initial begin
        // Initialize inputs
        a = 0;
        b = 0;
        
        // Wait for global reset
        #100;
        
        // Test case 1: 20 - 10 = 10
        a = 8'd20;
        b = 8'd10;
        #10;
        if (result !== 8'd10) $display("Test case 1 failed: %d - %d = %d", a, b, result);
        else $display("Test case 1 passed");
        
        // Test case 2: 0 - 1 = 255 (underflow)
        a = 8'd0;
        b = 8'd1;
        #10;
        if (result !== 8'd255) $display("Test case 2 failed: %d - %d = %d", a, b, result);
        else $display("Test case 2 passed");
        
        // Test case 3: 128 - 129 = 255 (underflow)
        a = 8'd128;
        b = 8'd129;
        #10;
        if (result !== 8'd255) $display("Test case 3 failed: %d - %d = %d", a, b, result);
        else $display("Test case 3 passed");
        
        $finish;
    end
endmodule

// and_op_tb.v - Testbench for AND operation module
module and_op_tb;
    // Inputs
    reg [7:0] a;
    reg [7:0] b;
    
    // Outputs
    wire [7:0] result;
    
    // Instantiate the Unit Under Test (UUT)
    and_op uut (
        .a(a),
        .b(b),
        .result(result)
    );
    
    initial begin
        // Initialize inputs
        a = 0;
        b = 0;
        
        // Wait for global reset
        #100;
        
        // Test case 1: 0xFF & 0xFF = 0xFF
        a = 8'hFF;
        b = 8'hFF;
        #10;
        if (result !== 8'hFF) $display("Test case 1 failed: 0x%h & 0x%h = 0x%h", a, b, result);
        else $display("Test case 1 passed");
        
        // Test case 2: 0xAA & 0x55 = 0x00
        a = 8'hAA;
        b = 8'h55;
        #10;
        if (result !== 8'h00) $display("Test case 2 failed: 0x%h & 0x%h = 0x%h", a, b, result);
        else $display("Test case 2 passed");
        
        // Test case 3: 0x0F & 0xFF = 0x0F
        a = 8'h0F;
        b = 8'hFF;
        #10;
        if (result !== 8'h0F) $display("Test case 3 failed: 0x%h & 0x%h = 0x%h", a, b, result);
        else $display("Test case 3 passed");
        
        $finish;
    end
endmodule

// or_op_tb.v - Testbench for OR operation module
module or_op_tb;
    // Inputs
    reg [7:0] a;
    reg [7:0] b;
    
    // Outputs
    wire [7:0] result;
    
    // Instantiate the Unit Under Test (UUT)
    or_op uut (
        .a(a),
        .b(b),
        .result(result)
    );
    
    initial begin
        // Initialize inputs
        a = 0;
        b = 0;
        
        // Wait for global reset
        #100;
        
        // Test case 1: 0x00 | 0x00 = 0x00
        a = 8'h00;
        b = 8'h00;
        #10;
        if (result !== 8'h00) $display("Test case 1 failed: 0x%h | 0x%h = 0x%h", a, b, result);
        else $display("Test case 1 passed");
        
        // Test case 2: 0xAA | 0x55 = 0xFF
        a = 8'hAA;
        b = 8'h55;
        #10;
        if (result !== 8'hFF) $display("Test case 2 failed: 0x%h | 0x%h = 0x%h", a, b, result);
        else $display("Test case 2 passed");
        
        // Test case 3: 0xF0 | 0x0F = 0xFF
        a = 8'hF0;
        b = 8'h0F;
        #10;
        if (result !== 8'hFF) $display("Test case 3 failed: 0x%h | 0x%h = 0x%h", a, b, result);
        else $display("Test case 3 passed");
        
        $finish;
    end
endmodule

// xor_op_tb.v - Testbench for XOR operation module
module xor_op_tb;
    // Inputs
    reg [7:0] a;
    reg [7:0] b;
    
    // Outputs
    wire [7:0] result;
    
    // Instantiate the Unit Under Test (UUT)
    xor_op uut (
        .a(a),
        .b(b),
        .result(result)
    );
    
    initial begin
        // Initialize inputs
        a = 0;
        b = 0;
        
        // Wait for global reset
        #100;
        
        // Test case 1: 0xFF ^ 0xFF = 0x00
        a = 8'hFF;
        b = 8'hFF;
        #10;
        if (result !== 8'h00) $display("Test case 1 failed: 0x%h ^ 0x%h = 0x%h", a, b, result);
        else $display("Test case 1 passed");
        
        // Test case 2: 0xAA ^ 0x55 = 0xFF
        a = 8'hAA;
        b = 8'h55;
        #10;
        if (result !== 8'hFF) $display("Test case 2 failed: 0x%h ^ 0x%h = 0x%h", a, b, result);
        else $display("Test case 2 passed");
        
        // Test case 3: 0xF0 ^ 0xF0 = 0x00
        a = 8'hF0;
        b = 8'hF0;
        #10;
        if (result !== 8'h00) $display("Test case 3 failed: 0x%h ^ 0x%h = 0x%h", a, b, result);
        else $display("Test case 3 passed");
        
        $finish;
    end
endmodule

// invert_tb.v - Testbench for INVERT operation module
module invert_tb;
    // Inputs
    reg [7:0] a;
    reg [7:0] b;
    
    // Outputs
    wire [7:0] result;
    
    // Instantiate the Unit Under Test (UUT)
    invert uut (
        .a(a),
        .b(b),
        .result(result)
    );
    
    initial begin
        // Initialize inputs
        a = 0;
        b = 0;
        
        // Wait for global reset
        #100;
        
        // Test case 1: ~0x00 = 0xFF
        a = 8'h00;
        b = 8'h00;  // Not used
        #10;
        if (result !== 8'hFF) $display("Test case 1 failed: ~0x%h = 0x%h", a, result);
        else $display("Test case 1 passed");
        
        // Test case 2: ~0xFF = 0x00
        a = 8'hFF;
        b = 8'h00;  // Not used
        #10;
        if (result !== 8'h00) $display("Test case 2 failed: ~0x%h = 0x%h", a, result);
        else $display("Test case 2 passed");
        
        // Test case 3: ~0xAA = 0x55
        a = 8'hAA;
        b = 8'h00;  // Not used
        #10;
        if (result !== 8'h55) $display("Test case 3 failed: ~0x%h = 0x%h", a, result);
        else $display("Test case 3 passed");
        
        $finish;
    end
endmodule

// shift_left_tb.v - Testbench for Shift Left operation module
module shift_left_tb;
    // Inputs
    reg [7:0] a;
    reg [7:0] b;
    
    // Outputs
    wire [7:0] result;
    
    // Instantiate the Unit Under Test (UUT)
    shift_left uut (
        .a(a),
        .b(b),
        .result(result)
    );
    
    initial begin
        // Initialize inputs
        a = 0;
        b = 0;
        
        // Wait for global reset
        #100;
        
        // Test case 1: 0x01 << 0 = 0x01
        a = 8'h01;
        b = 8'h00;
        #10;
        if (result !== 8'h01) $display("Test case 1 failed: 0x%h << %d = 0x%h", a, b[2:0], result);
        else $display("Test case 1 passed");
        
        // Test case 2: 0x01 << 3 = 0x08
        a = 8'h01;
        b = 8'h03;
        #10;
        if (result !== 8'h08) $display("Test case 2 failed: 0x%h << %d = 0x%h", a, b[2:0], result);
        else $display("Test case 2 passed");
        
        // Test case 3: 0x10 << 4 = 0x00 (overflow)
        a = 8'h10;
        b = 8'h04;
        #10;
        if (result !== 8'h00) $display("Test case 3 failed: 0x%h << %d = 0x%h", a, b[2:0], result);
        else $display("Test case 3 passed");
        
        $finish;
    end
endmodule

// shift_right_tb.v - Testbench for Shift Right operation module
module shift_right_tb;
    // Inputs
    reg [7:0] a;
    reg [7:0] b;
    
    // Outputs
    wire [7:0] result;
    
    // Instantiate the Unit Under Test (UUT)
    shift_right uut (
        .a(a),
        .b(b),
        .result(result)
    );
    
    initial begin
        // Initialize inputs
        a = 0;
        b = 0;
        
        // Wait for global reset
        #100;
        
        // Test case 1: 0x80 >> 0 = 0x80
        a = 8'h80;
        b = 8'h00;
        #10;
        if (result !== 8'h80) $display("Test case 1 failed: 0x%h >> %d = 0x%h", a, b[2:0], result);
        else $display("Test case 1 passed");
        
        // Test case 2: 0x80 >> 3 = 0x10
        a = 8'h80;
        b = 8'h03;
        #10;
        if (result !== 8'h10) $display("Test case 2 failed: 0x%h >> %d = 0x%h", a, b[2:0], result);
        else $display("Test case 2 passed");
        
        // Test case 3: 0x01 >> 1 = 0x00
        a = 8'h01;
        b = 8'h01;
        #10;
        if (result !== 8'h00) $display("Test case 3 failed: 0x%h >> %d = 0x%h", a, b[2:0], result);
        else $display("Test case 3 passed");
        
        $finish;
    end
endmodule

// mux_8to1_tb.v - Testbench for 8-to-1 Multiplexer
module mux_8to1_tb;
    // Inputs
    reg [7:0] in0, in1, in2, in3, in4, in5, in6, in7;
    reg [2:0] select;
    
    // Outputs
    wire [7:0] out;
    
    // Instantiate the Unit Under Test (UUT)
    mux_8to1 uut (
        .in0(in0),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .in4(in4),
        .in5(in5),
        .in6(in6),
        .in7(in7),
        .select(select),
        .out(out)
    );
    
    initial begin
        // Initialize inputs
        in0 = 8'hA0;  // Addition
        in1 = 8'hA1;  // Subtraction
        in2 = 8'hA2;  // AND
        in3 = 8'hA3;  // OR
        in4 = 8'hA4;  // XOR
        in5 = 8'hA5;  // INVERT
        in6 = 8'hA6;  // Shift Left
        in7 = 8'hA7;  // Shift Right
        select = 3'b000;
        
        // Wait for global reset
        #100;
        
        // Test all select values
        for (select = 3'b000; select <= 3'b111; select = select + 1) begin
            #10;
            case(select)
                3'b000: 
                    if (out !== in0) $display("Select %b failed: expected 0x%h, got 0x%h", select, in0, out);
                    else $display("Select %b passed", select);
                3'b001: 
                    if (out !== in1) $display("Select %b failed: expected 0x%h, got 0x%h", select, in1, out);
                    else $display("Select %b passed", select);
                3'b010: 
                    if (out !== in2) $display("Select %b failed: expected 0x%h, got 0x%h", select, in2, out);
                    else $display("Select %b passed", select);
                3'b011: 
                    if (out !== in3) $display("Select %b failed: expected 0x%h, got 0x%h", select, in3, out);
                    else $display("Select %b passed", select);
                3'b100: 
                    if (out !== in4) $display("Select %b failed: expected 0x%h, got 0x%h", select, in4, out);
                    else $display("Select %b passed", select);
                3'b101: 
                    if (out !== in5) $display("Select %b failed: expected 0x%h, got 0x%h", select, in5, out);
                    else $display("Select %b passed", select);
                3'b110: 
                    if (out !== in6) $display("Select %b failed: expected 0x%h, got 0x%h", select, in6, out);
                    else $display("Select %b passed", select);
                3'b111: 
                    if (out !== in7) $display("Select %b failed: expected 0x%h, got 0x%h", select, in7, out);
                    else $display("Select %b passed", select);
            endcase
        end
        
        $finish;
    end
endmodule

// alu_top_tb.v - Testbench for the complete ALU
module alu_top_tb;
    // Inputs
    reg [7:0] opA;
    reg [7:0] opB;
    reg [2:0] opS;
    
    // Outputs
    wire [7:0] Result;
    
    // Instantiate the Unit Under Test (UUT)
    alu_top uut (
        .opA(opA),
        .opB(opB),
        .opS(opS),
        .Result(Result)
    );
    
    initial begin
        // Initialize inputs
        opA = 0;
        opB = 0;
        opS = 0;
        
        // Wait for global reset
        #100;
        
        // Test Addition: 25 + 40 = 65
        opA = 8'd25;
        opB = 8'd40;
        opS = 3'b000;  // Addition
        #10;
        $display("Addition: %d + %d = %d", opA, opB, Result);
        
        // Test Subtraction: 50 - 30 = 20
        opA = 8'd50;
        opB = 8'd30;
        opS = 3'b001;  // Subtraction
        #10;
        $display("Subtraction: %d - %d = %d", opA, opB, Result);
        
        // Test AND: 0xF0 & 0x0F = 0x00
        opA = 8'hF0;
        opB = 8'h0F;
        opS = 3'b010;  // AND
        #10;
        $display("AND: 0x%h & 0x%h = 0x%h", opA, opB, Result);
        
        // Test OR: 0xF0 | 0x0F = 0xFF
        opA = 8'hF0;
        opB = 8'h0F;
        opS = 3'b011;  // OR
        #10;
        $display("OR: 0x%h | 0x%h = 0x%h", opA, opB, Result);
        
        // Test XOR: 0xFF ^ 0x0F = 0xF0
        opA = 8'hFF;
        opB = 8'h0F;
        opS = 3'b100;  // XOR
        #10;
        $display("XOR: 0x%h ^ 0x%h = 0x%h", opA, opB, Result);
        
        // Test INVERT: ~0xAA = 0x55
        opA = 8'hAA;
        opB = 8'h00;  // Not used
        opS = 3'b101;  // INVERT
        #10;
        $display("INVERT: ~0x%h = 0x%h", opA, Result);
        
        // Test Shift Left: 0x01 << 3 = 0x08
        opA = 8'h01;
        opB = 8'h03;  // Shift by 3
        opS = 3'b110;  // Shift Left
        #10;
        $display("Shift Left: 0x%h << %d = 0x%h", opA, opB[2:0], Result);
        
        // Test Shift Right: 0x80 >> 4 = 0x08
        opA = 8'h80;
        opB = 8'h04;  // Shift by 4
        opS = 3'b111;  // Shift Right
        #10;
        $display("Shift Right: 0x%h >> %d = 0x%h", opA, opB[2:0], Result);
        
        $finish;
    end
endmodule

// alu_constants.v - Common constants for the ALU project
module alu_constants;
    // Operation codes
    parameter ADD_OP      = 3'b000;
    parameter SUBTRACT_OP = 3'b001;
    parameter AND_OP      = 3'b010;
    parameter OR_OP       = 3'b011;
    parameter XOR_OP      = 3'b100;
    parameter INVERT_OP   = 3'b101;
    parameter SHIFT_L_OP  = 3'b110;
    parameter SHIFT_R_OP  = 3'b111;
    
    // You can add other common constants here if needed
endmodule

// alu_project.v - Main project wrapper for the ALU
module alu_project;
   
    // Example: Instantiate ALU with specific input/output connections
    wire [7:0] opA, opB, Result;
    wire [2:0] opS;
    
    // Example registers for storing intermediate values
    reg [7:0] operandA_reg, operandB_reg;
    reg [2:0] operation_reg;
    
    // Instantiate the ALU
    alu_top main_alu (
        .opA(opA),
        .opB(opB),
        .opS(opS),
        .Result(Result)
    );
    
    // Connect the wires to the registers
    assign opA = operandA_reg;
    assign opB = operandB_reg;
    assign opS = operation_reg;
    
    // This could include more logic for interfacing with other components
    // or for setting up a test environment
endmodule