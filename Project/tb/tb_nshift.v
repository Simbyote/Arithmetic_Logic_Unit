/*
 * tb_nShift.v
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
module tb_nShift;
    parameter WIDTH = 4;    // The number of bits for the input-output
    parameter BIT_STATE = 2 ** WIDTH;   // The total possible states for the given bit WIDTH

    reg [ WIDTH-1:0 ] in;
    reg [ WIDTH-1:0 ] shift;
    wire [ WIDTH-1:0 ] out_logical, out_arithmetic, overflow_logical, overflow_arithmetic;

    // Logical shift right
    nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shift_logical(
        .in( in ),
        .shift( shift ),
        .out( out_logical ),
        .overflow( overflow_logical )
    );

    nBit_Shift #( .WIDTH( WIDTH ), .OP( 1 ) ) shift_arithmetic(
        .in( in ),
        .shift( shift ),
        .out( out_arithmetic ),
        .overflow( overflow_arithmetic )
    );

    /*
     * Tests the inputs that each shift module can receives
     * The test iterates through all possible input values and shift amounts
     * for both logical and arithmetic shift operations
     */
    task test_nShift;
        integer shift_dir, shift_amt, fill_bit, idx, MAX_SHIFT;
        begin
            // Initialize inputs
            shift = { WIDTH{ 1'b0 } };
            in = { WIDTH{ 1'b0 } };

            // Iterate through all shift directions
            for( shift_dir = 0; shift_dir < 2; shift_dir = shift_dir + 1 ) begin

                if( shift_dir == 0 ) begin
                    MAX_SHIFT = ( WIDTH - 1 );
                end
                else begin
                    MAX_SHIFT = ( WIDTH / 2 );
                end
                // Iterate through all shift amounts
                for( shift_amt = 1; shift_amt <= MAX_SHIFT; shift_amt = shift_amt + 1 ) begin

                    // Iterate through all fill bits
                    for( fill_bit = 0; fill_bit < 2; fill_bit = fill_bit + 1 ) begin

                        // Construct the shift
                        shift[ WIDTH-1 ] = fill_bit; 
                        shift[ WIDTH-2:1 ] = shift_amt; 
                        shift[ 0 ] = shift_dir;

                        // Iterate through all possible input states
                        repeat( BIT_STATE ) begin
                            in = in + 1;
                            #10;
                        end
                    end
                end
            end
        end
    endtask

    


    initial begin
        $dumpfile( "waveform4.vcd" );
        $dumpvars( 0, tb_nShift );

            test_nShift;

        $finish;
    end
endmodule