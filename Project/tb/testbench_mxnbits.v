/*
 * testbench_mxnbits.v
 * 
 * Purpose:
 * - This file serves as a testbench for the mXnBits gates implemented in mXnBits_gates.v
 * - It verifies the correctness of each gate's logic by testing all possible m-bit input combinations
 *
 * Overview:
 * - The testbench instantiates the following mXnBits gates: NOT, AND, OR, NAND, NOR, XOR, and XNOR
 * - Each gate is connected to test inputs and has unique outputs
 * - The `test_mXnBits` task generates all possible input states and applies them to the gates
 *
 * Waveform:
 * - The simulation generates a VCD file named `waveform3.vcd` for visualization
 */
`timescale 1ns/1ns
module testbench_mXnBits;
    parameter WIDTH = 4;              // The number of bits for the input-output
    parameter BIT_STATE = 2 ** WIDTH; // The total possible states for the given bit WIDTH
    parameter SETS = 2;               // The number of binary values to evaluate at a time

    /*
     * Packed input signals & unique output signals for each mXnBits gate
     */
    wire [ SETS*WIDTH-1:0 ] in1_packed, in2_packed;
    wire [ SETS*WIDTH-1:0 ] NOT_out_packed,
                        AND_out_packed, 
                        OR_out_packed, 
                        NAND_out_packed, 
                        NOR_out_packed, 
                        XOR_out_packed, 
                        XNOR_out_packed;
    
    /*
     * Instantiate each mXnBits gate
     */
    mXnBit_NOT #( .WIDTH( WIDTH ), .SETS( SETS ) ) not_instance (
        .in_packed( in1_packed ),
        .out_packed( NOT_out_packed )
    );

    mXnBit_AND #( .WIDTH( WIDTH ), .SETS( SETS ) ) and_instance (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( AND_out_packed )
    );

    mXnBit_OR #( .WIDTH( WIDTH ), .SETS( SETS ) ) or_instance (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( OR_out_packed )
    );

    mXnBit_NAND #( .WIDTH( WIDTH ), .SETS( SETS ) ) nand_instance (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( NAND_out_packed )
    );

    mXnBit_NOR #( .WIDTH( WIDTH ), .SETS( SETS ) ) nor_instance (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( NOR_out_packed )
    );

    mXnBit_XOR #( .WIDTH( WIDTH ), .SETS( SETS ) ) xor_instance (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( XOR_out_packed )
    );

    mXnBit_XNOR #( .WIDTH( WIDTH ), .SETS( SETS ) ) xnor_instance (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( XNOR_out_packed )
    );

    /*
     * Unpacked input signals & unique output signals for each mXnBits gate    
     */
    reg [ WIDTH-1:0 ] in1_unpacked[ SETS-1:0 ];
    reg [ WIDTH-1:0 ] in2_unpacked[ SETS-1:0 ];

    wire [ WIDTH-1:0 ] NOT_out_unpacked[ SETS-1:0 ];
    wire [ WIDTH-1:0 ] AND_out_unpacked[ SETS-1:0 ];
    wire [ WIDTH-1:0 ] OR_out_unpacked[ SETS-1:0 ];
    wire [ WIDTH-1:0 ] NAND_out_unpacked[ SETS-1:0 ];
    wire [ WIDTH-1:0 ] NOR_out_unpacked[ SETS-1:0 ];
    wire [ WIDTH-1:0 ] XOR_out_unpacked[ SETS-1:0 ];
    wire [ WIDTH-1:0 ] XNOR_out_unpacked[ SETS-1:0 ];

    /*
     * Unpack each mXnBits gate's packed output signals into individual 2D arrays
     */
    genvar i;
    generate
        for( i = 0; i < SETS; i = i + 1 ) begin : unpack_inputs
            assign in1_packed[ i*WIDTH +:WIDTH ] = in1_unpacked[ i ];
            assign in2_packed[ i*WIDTH +:WIDTH ] = in2_unpacked[ i ];

            assign NOT_out_packed[ i*WIDTH +:WIDTH ] = NOT_out_unpacked[ i ];
            assign AND_out_packed[ i*WIDTH +:WIDTH ] = AND_out_unpacked[ i ];
            assign OR_out_packed[ i*WIDTH +:WIDTH ] = OR_out_unpacked[ i ];
            assign NAND_out_packed[ i*WIDTH +:WIDTH ] = NAND_out_unpacked[ i ];
            assign NOR_out_packed[ i*WIDTH +:WIDTH ] = NOR_out_unpacked[ i ];
            assign XOR_out_packed[ i*WIDTH +:WIDTH ] = XOR_out_unpacked[ i ];
            assign XNOR_out_packed[ i*WIDTH +:WIDTH ] = XNOR_out_unpacked[ i ];
        end
    endgenerate

    /*
     * Test the inputs that each gate receives
     * The test iterates through all possible states for the given bit WIDTH
     * a number of SETS times for both input signals in1 and in2
     */
    task test_mXnBits;
        integer idx;
        begin
            // Initialize inputs
            for( idx = 0; idx < SETS; idx = idx + 1 ) begin
                in1_unpacked[ idx ] = { WIDTH{ 1'b0 } };
                in2_unpacked[ idx ] = { WIDTH{ 1'b0 } };
            end

            repeat( BIT_STATE ) begin
                for( idx = 0; idx < SETS; idx = idx + 1 ) begin
                    repeat( BIT_STATE ) begin
                        #10;
                        in2_unpacked[ idx ] = in2_unpacked[ idx ] + 1;
                    end
                end
                for( idx = 0; idx < SETS; idx = idx + 1 ) begin
                    in1_unpacked[ idx ] = in1_unpacked[ idx ] + 1;
                end
            end

            // Pull inputs low after all test cases are executed
            for( idx = 0; idx < SETS; idx = idx + 1 ) begin
                in1_unpacked[ idx ] = { WIDTH{ 1'b0 } };
                in2_unpacked[ idx ] = { WIDTH{ 1'b0 } };
                #10;
            end

        end
    endtask

    initial begin   // Begin simulation
        /*
         * Generate waveform for simulation:
         *
         * - File: `waveform3.vcd` (Visualize in GTKWave)
         * - Includes all signals from the testbench_mXnBits module
         */
        $dumpfile( "waveform3.vcd" );
        $dumpvars( 0, testbench_mXnBits );

        test_mXnBits;
        
        $finish;    // End simulation
    end
endmodule
