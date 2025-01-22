/*
 * testbench_nShift.v
 *
 * Purpose:
 * - This file serves as a testbench for the n-bit shift module implemented in arithmetic_operations.v
 * - It verifies the correctness of the logical and arithmetic shift operations
 *
 * Overview:
 * - The testbench instantiates the nBit_Shift module for logical and arithmetic shift operations
 * - The `test_nShift` task generates all possible input states and applies them to the shift modules
 *
 * Waveform:
 * - The simulation generates a VCD file named `waveform4.vcd` for visualization
 */

`timescale 1ns/1ns
module testbench_nShift;
    parameter WIDTH = 4;    // The number of bits for the input-output
    parameter BIT_STATE = 2 ** WIDTH;   // The total possible states for the given bit WIDTH

    
    reg [ WIDTH-1:0 ] in;
    reg shift_dir;
    reg [ WIDTH-1:0 ] shift_amt;
    wire [ WIDTH-1:0 ] out_logical, out_arithmetic;

    // Logical shift right
    nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shift_logical(
        .in( in ),
        .shift_dir( shift_dir ),
        .shift_amt( shift_amt ),
        .out( out_logical )
    );

    // Arithmetic shift right
    nBit_Shift #( .WIDTH( WIDTH ), .OP( 1 ) ) shift_arithmetic(
        .in( in ),
        .shift_dir( shift_dir ),
        .shift_amt( shift_amt ),
        .out( out_arithmetic )
    );

    /*
     * Tests the inputs that each shift module can receives
     * The test iterates through all possible input values and shift amounts
     * for both logical and arithmetic shift operations
     */
    task test_nShift;
    integer MAX_SHIFT;  // Maximum shift amount based on direction
    begin
        // Initialize inputs
        shift_dir = 0;
        in = { WIDTH{ 1'b0 } };

        // Iterate through shift directions
        repeat ( 2 ) begin
            // Determine maximum shift amount based on direction
            if (shift_dir == 0)
                MAX_SHIFT = WIDTH - 1;    // Left shift
            else
                MAX_SHIFT = (WIDTH / 2);  // Right shift

            // Iterate through shift amounts
            shift_amt = 1;
            repeat ( MAX_SHIFT ) begin
                // Initialize the input value
                in = { WIDTH{ 1'b0 } };

                // Iterate through all input values
                repeat ( BIT_STATE ) begin
                    #10;
                    in = in + 1;
                end
                shift_amt = shift_amt + 1;
            end

            // Switch to the next shift direction
            shift_dir = shift_dir + 1;
        end

        // Pull inputs low after all test cases are executed
        in = { WIDTH{ 1'b0 } };
        shift_dir = 0;
        shift_amt = 0;
        #10;
    end
endtask


    initial begin
        $dumpfile( "waveform4.vcd" );
        $dumpvars( 0, testbench_nShift );

            test_nShift;

        $finish;
    end
endmodule