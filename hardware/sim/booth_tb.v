`timescale 1ns / 1ps

module booth_tb();

    // Inputs
    reg clk;
    reg load;
    reg reset;
    reg [31:0] M;
    reg [31:0] Q;

    // Outputs
    wire [63:0] P;

    // Instantiate the Booth's Algorithm module
    booth uut(
        .clk(clk),
        .load(load),
        .reset(reset),
        .M(M),
        .Q(Q),
        .P(P));

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10 ns clock period
    end

    // Test procedure
    initial begin
        // Test case 1: M = -5, Q = -6 (expected result: 30)
        run_test_case(32'b1111_1111_1111_1111_1111_1111_1111_1011, // -5 in 32-bit 2's complement
                      32'b1111_1111_1111_1111_1111_1111_1111_1010); // -6 in 32-bit 2's complement

        // Test case 2: M = 5, Q = 6 (expected result: 30)
        run_test_case(32'b0000_0000_0000_0000_0000_0000_0000_0101, // 5 in 32-bit 2's complement
                      32'b0000_0000_0000_0000_0000_0000_0000_0110); // 6 in 32-bit 2's complement

        // Test case 3: M = -7, Q = 4 (expected result: -28)
        run_test_case(32'b1111_1111_1111_1111_1111_1111_1111_1001, // -7 in 32-bit 2's complement
                      32'b0000_0000_0000_0000_0000_0000_0000_0100); // 4 in 32-bit 2's complement

        // Test case 4: M = 10, Q = -3 (expected result: -30)
        run_test_case(32'b0000_0000_0000_0000_0000_0000_0000_1010, // 10 in 32-bit 2's complement
                      32'b1111_1111_1111_1111_1111_1111_1111_1101); // -3 in 32-bit 2's complement

        // Test case 5: M = 15, Q = 15 (expected result: 225)
        run_test_case(32'b0000_0000_0000_0000_0000_0000_0000_1111, // 15 in 32-bit 2's complement
                      32'b0000_0000_0000_0000_0000_0000_0000_1111); // 15 in 32-bit 2's complement
                      
        // Maximum positive 32-bit signed number and minimum negative 32-bit signed number
        run_test_case(32'b0111_1111_1111_1111_1111_1111_1111_1111, // Max positive 32-bit signed integer: 2147483647
              32'b1000_0000_0000_0000_0000_0000_0000_0000); // Min negative 32-bit signed integer: -2147483648

        // Maximum positive 32-bit signed number multiplied by a small positive number
        run_test_case(32'b0111_1111_1111_1111_1111_1111_1111_1111, // Max positive 32-bit signed integer: 2147483647
              32'b0000_0000_0000_0000_0000_0000_0000_0010); // Small positive number: 2

        // Minimum negative 32-bit signed number multiplied by a small positive number
        run_test_case(32'b1000_0000_0000_0000_0000_0000_0000_0000, // Min negative 32-bit signed integer: -2147483648
              32'b0000_0000_0000_0000_0000_0000_0000_0010); // Small positive number: 2

        // Maximum positive 20-bit number extended to 32-bits, multiplied by another 20-bit number extended to 32-bits
        run_test_case(32'b0000_0000_0000_0000_0000_1111_1111_1111, // Max positive 20-bit number extended: 1048575
              32'b0000_0000_0000_0000_0000_1111_1111_1110); // Just below max 20-bit number: 1048574

        // Minimum negative 20-bit number extended to 32-bits, multiplied by another 20-bit negative number extended to 32-bits
        run_test_case(32'b1111_1111_1111_1111_1111_0000_0000_0000, // Min negative 20-bit number extended: -1048576
              32'b1111_1111_1111_1111_1111_0000_0000_0001); // Just above min 20-bit number: -1048575

        // Smallest possible signed 32-bit number (negative one) and positive one
        run_test_case(32'b1111_1111_1111_1111_1111_1111_1111_1111, // -1
              32'b0000_0000_0000_0000_0000_0000_0000_0001); // 1

        // Testing with zero in one operand
        run_test_case(32'b0000_0000_0000_0000_0000_0000_0000_0000, // 0
              32'b0000_0000_0000_0000_1111_1111_1111_1111); // 16-bit max positive number: 65535

        run_test_case(32'b1111_1111_1111_1111_1111_1111_1111_1111, // -1 (smallest possible negative signed 32-bit number)
              32'b0000_0000_0000_0000_1111_1111_1111_1111); // 16-bit max positive number: 65535

        // Very large positive numbers near the upper limit of the 32-bit range
        run_test_case(32'b0000_0000_1111_1111_1111_1111_1111_1111, // Large positive number close to 2^24: 16777215
              32'b0000_0000_1111_1111_1111_1111_1111_1101); // Slightly smaller large positive number: 16777213

        // Very large negative numbers near the lower limit of the 32-bit range
        run_test_case(32'b1111_1111_0000_0000_0000_0000_0000_0001, // Large negative number close to -2^24: -16777215
              32'b1111_1111_0000_0000_0000_0000_0000_0011); // Another large negative: -16777213


        // Finish simulation
        $stop;
    end

   // Task to run a single test case
task run_test_case(input [31:0] M_val, input [31:0] Q_val);
    begin
        // Apply reset
        reset = 1;
        load = 0;
        M = 32'b0;
        Q = 32'b0;
        #10;
        reset = 0;

        // Load values into M and Q
        M = M_val;
        Q = Q_val;
        load = 1;
        #10;
        load = 0;

        // Allow sufficient time for the multiplication process
        #1000;

        // Add a short delay to ensure all signals have settled
        #1; // Wait for a single time unit
        //$display("Time = %0t, M = %0d, Q = %0d, Result (P) = %0d", $time, M, Q, P);
        $display("Time = %0t | M = %11d | Q = %11d | Result (P) = %20d", $time, M, Q, P);

        // Apply reset before the next test case
        reset = 1;
        #10;
        reset = 0;
    end
endtask

endmodule

