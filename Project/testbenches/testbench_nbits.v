/*
 * testbench_nbits.v
 * 
 * Purpose:
 * - This file contains a testbench for the n-bit arithmetic and logical modules
 *   defined in nbit_arithmetic.v
 *
 * Overview:
 * - The testbench instantiates the following n-bit gates: NOT, AND, OR, NAND, NOR, XOR, and XNOR
 * - Each gate is connected to test inputs and has unique outputs
 * - The `test_nBits` task generates all possible input states and applies them to the gates
 *
 * Waveform:
 * - The simulation generates a VCD file named `waveform2.vcd` for visualization
 */

`timescale 1ns/1ns
module testbench_nbits;
    parameter WIDTH = 4;    // The number of bits for the input-output
    parameter BIT_STATE = 2 ** WIDTH;   // The total possible states for the given bit WIDTH
    
    /*
     * Input signals & unique output signals for each nBit gate
     */
    reg [ WIDTH-1:0 ] in1, in2;
    wire [ WIDTH-1:0 ] NOT_out, AND_out, OR_out, NAND_out, NOR_out, XOR_out, XNOR_out;

    /*
     * Instantiate each nBit gate
     */
    nBit_NOT #( .WIDTH( WIDTH ) ) not_instance (
        .in( in1 ),
        .out( NOT_out )
    );
    nBit_AND #( .WIDTH( WIDTH ) ) and_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( AND_out )
    );
    nBit_OR #( .WIDTH( WIDTH ) ) or_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( OR_out )
    );
    nBit_NAND #( .WIDTH( WIDTH ) ) nand_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( NAND_out )
    );
    nBit_NOR #( .WIDTH( WIDTH ) ) nor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( NOR_out )
    );
    nBit_XOR #( .WIDTH( WIDTH ) ) xor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( XOR_out )
    );
    nBit_XNOR #( .WIDTH( WIDTH ) ) xnor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( XNOR_out )
    );

    /*
     * Tests the inputs that each gate receives
     * The test iterates through all possible states for the given bit WIDTH
     * for both input signals in1 and in2
     */
    task test_nBits;
        begin
            // Initialize inputs
            in1 = { WIDTH{ 1'b0 } };

            repeat( BIT_STATE ) begin
                // Initialize the second input signal
                in2 = { WIDTH{ 1'b0 } };
                repeat( BIT_STATE ) begin
                    #10;
                    in2 = in2 + 1;
                end
                in1 = in1 + 1;
            end

        // Pull the inputs low after all test cases are executed
        in1 = { WIDTH{ 1'b0 } };
        in2 = { WIDTH{ 1'b0 } };
        #10;
        end
    endtask

    initial begin   // Begin simulation
        /*
         * Generate waveform for simulation:
         *
         * - File: `waveform2.vcd` (Visualize in GTKWave)
         * - Includes all signals in the testbench_nbits module
         */
        $dumpfile( "waveform2.vcd" );
        $dumpvars( 0, testbench_nbits );

        test_nBits;

        $finish;    // End simulation
    end
endmodule