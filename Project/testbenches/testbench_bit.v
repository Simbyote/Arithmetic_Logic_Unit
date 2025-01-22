/*
 * testbench_bit.v
 *
 * Purpose:
 * - This file serves as a testbench for the logic gates implemented in bit_gates.v
 * - It verifies the correctness of each gate's logic by testing all possible 1-bit input combinations
 *
 * Overview:
 * - The testbench instantiates the following gates: NOT, AND, OR, NAND, NOR, XOR, and XNOR
 * - Each gate is connected to test inputs and has unique outputs
 * - The `test_bit` task generates all possible input states and applies them to the gates
 *
 * Waveform:
 * - The simulation generates a VCD file named `waveform1.vcd` for visualization
 */


`timescale 1ns/1ns
module testbench_bit;
    /*
     * Input signals & unique output signals for each gate
     */
     reg [ 0:0 ] in, in1, in2;
     wire [ 0:0 ] NOT_out, AND_out, OR_out, NAND_out, NOR_out, XOR_out, XNOR_out;

    /*
     * Instantiate each logic gate
     */
    NOT not_instance (
        .in( in1 ),
        .out( NOT_out )
    );
    AND and_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( AND_out )
    );
    OR or_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( OR_out )
    );
    NAND nand_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( NAND_out )
    );
    NOR nor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( NOR_out )
    );
    XOR xor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( XOR_out )
    );
    XNOR xnor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( XNOR_out )
    );

    /*
     * Tests the inputs that each gate receives
     * The test iterates through all possible 1-bit input states
     * for both input signals in1 and in2
     */
    task test_bit;
        begin
            // Initialize the first input signal
            in1 = { 1'b0 };

            repeat( 2 ) begin
                // Initialize the second input signal
                in2 = { 1'b0 };
                repeat( 2 ) begin
                    #10;
                    in2 = in2 + 1;
                end
                in1 = in1 + 1;
            end

        // Pull inputs low after all test cases are executed
        in1 = { 1'b0 };
        in2 = { 1'b0 };
        end
    endtask

    initial begin   // Begin simulation
        /*
         * Generate waveform for simulation:
         *
         * - File: `waveform1.vcd` (Visualize using GTKWave)
         * - Includes all signals in the testbench_bit module
         */
        $dumpfile( "waveform1.vcd" );
        $dumpvars( 0, testbench_bit );

        test_bit;

        $finish;    // End simulation
    end
endmodule