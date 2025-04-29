`timescale 1ns / 1ps

module booth(
    input clk,
    input load,
    input reset,

    input [31:0] M, // Multiplicand
    input [31:0] Q, //32-bit signed 2's complement inputs
    
    output reg [63:0] P // 64-bit signed 2's complement Product
    );
    
    // Internal signals
    reg signed [63:0] A = 64'b0;        // 64 bit Accumulator handle sign extension 
    reg signed [31:0] Q_temp = 32'b0;   // Temp register for Q
    reg signed [31:0] M_temp = 32'b0;   // Temp register for M
    reg [4:0] Count = 5'd16;            // Counter for radix-4 iterations 
    reg Q_minus_one = 0;                // Previous bit of Q for Booth's algorithm 01_"0"

    always @(posedge clk)
    begin
        if (reset == 1) 
        begin
            
            A = 64'b0;
            Q_minus_one = 0;
            P = 64'b0;
            Q_temp = 32'b0;
            M_temp = 32'b0;
            Count = 5'd16;
        end
        else if (load == 1)
        begin
          
            Q_temp = Q;
            M_temp = M;
            A = 64'b0;   // Reset A back to 0 when loading new values
            Q_minus_one = 0; // Reset Q[-1]
        end
        else if (Count > 5'd0)
        begin
            // Check 3 bit pattern {Q[1:0], Q_minus_one}
            case ({Q_temp[1:0], Q_minus_one})
                3'b000, 3'b111:  // No operation 
                    begin
                        
                    end
                3'b001, 3'b010:  // Add M (+1M or +1*M)
                    begin
                        // Sign-extend M_temp to 64 bits and add to A
                        A = A + {{32{M_temp[31]}}, M_temp};
                    end
                3'b011:  // Add 2M (+2M or +2 * M)
                    begin
                        // Sign-extend and shift M_temp left by 1 (multiply by 2)
                        A = A + ({{32{M_temp[31]}}, M_temp} << 1); 
                    end
                3'b100:  // Subtract 2M (-2M or -2 * M)
                    begin
                        // Sign-extend and shift left by 1 (multiply by 2)
                        A = A - ({{32{M_temp[31]}}, M_temp} << 1); 
                    end
                3'b101, 3'b110:  // Subtract M (-1M or -1*M)
                    begin
                        // Sign-extend M_temp to 64 bits and subtract from A
                        A = A - {{32{M_temp[31]}}, M_temp}; 
                    end
            endcase

            // Update Q_minus_one, 
            // perform an arithmetic right shift on both A and Q_temp by 2 bits
            Q_minus_one = Q_temp[1];
            Q_temp = {A[1:0], Q_temp[31:2]};  // Logical right shift Q_temp by 2 bits
            A = {A[63], A[63:2]};  // Arithmetic right shift A by 2 bits to preserve sign bit

            // Decrement count for each iteration
            Count = Count - 1'b1;
        end
        else
        begin
            // Stop when count reaches zero
            Count = 5'b0;
        end

        // Combine A and Q_temp to produce the final 64-bit product
        P = {A[31:0], Q_temp};
    end

endmodule