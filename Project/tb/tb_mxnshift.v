/*
 * tb_mXnShift.v
 *
 * Purpose:
 * - This file serves as a testbench for the mXnBits_Shift module implemented in mXnBits_Shift.v
 * - It verifies the correctness of the logical and arithmetic shift operations for mXn-bit inputs
 * 
 * Overview:
 * - The testbench instantiates the mXnBits_Shift module for logical and arithmetic shift operations
 * - The `test_mXnShift` task generates all possible input states and applies them to the shift modules
 *
 * Waveform:
 * - The simulation generates a VCD file named `waveform5.vcd` for visualization
 */
`timescale 1ns/1ns
module tb_mXnShift;
    parameter WIDTH = 4;
    parameter BIT_STATE = 2 ** WIDTH;
    parameter SETS = 2;

    /*
     * Input signals & unique output signals for each mXnBit shift module
     */
    wire [ SETS*WIDTH-1:0 ] 
    in_packed, 
    shift_packed,
    out_packed_logical, 
    out_packed_arithmetic,
    overflow_packed_logical,
    overflow_packed_arithmetic;

    /*
     * Instantiate the mXnBits_Shift module for logical and arithmetic shifts
     */
    mXnBits_Shift #( .WIDTH( WIDTH ), .SETS( SETS ), .OP( 0 ) ) shift_logical(
        .in_packed( in_packed ),
        .shift_packed( shift_packed ),
        .out_packed( out_packed_logical ),
        .overflow_packed( overflow_packed_logical )
    );

    mXnBits_Shift #( .WIDTH( WIDTH ), .SETS( SETS ), .OP( 1 ) ) shift_arithmetic(
        .in_packed( in_packed ),
        .shift_packed( shift_packed ),
        .out_packed( out_packed_arithmetic ),
        .overflow_packed( overflow_packed_arithmetic )
    );

    // Unpacked inputs and unique outputs for type of shift
    reg [ WIDTH-1:0 ] in_unpacked [ SETS-1:0 ];
    reg [ WIDTH-1:0 ] shift_unpacked [ SETS-1:0 ];
    wire [ WIDTH-1:0 ] out_unpacked_logical [ SETS-1:0 ];
    wire [ WIDTH-1:0 ] out_unpacked_arithmetic [ SETS-1:0 ];
    wire [ WIDTH-1:0 ] overflow_unpacked_logical [ SETS-1:0 ];
    wire [ WIDTH-1:0 ] overflow_unpacked_arithmetic [ SETS-1:0 ];

    // Unpack the inputs
    genvar i;
    generate
        for( i = 0; i < SETS; i = i + 1 ) begin : unpack_inputs
            assign in_packed[ i*WIDTH +: WIDTH ] = in_unpacked[ i ];
            assign shift_packed[ i*WIDTH +: WIDTH ] = shift_unpacked[ i ];
        end
    endgenerate

    /*
     * Tests the inputs that each shift module can receive
     * The test iterates through all possible input values and shift amounts
     * for both logical and arithmetic shift operations
     */
    task test_mXnShift;
        integer shift_dir, shift_amt, fill_bit, MAX_SHIFT, i, j;

        begin
            for( i = 0; i < SETS; i = i + 1 ) begin
                in_unpacked[ i ] = { WIDTH{ 1'b0 } };
                shift_unpacked[ i ] = { WIDTH{ 1'b0 } };
            end

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
                        
                        for( i = 0; i < SETS; i = i + 1 ) begin
                            // Set the shift direction
                            shift_unpacked[ i ][ WIDTH-1 ] = fill_bit; 
                            shift_unpacked[ i ][ WIDTH-2:1 ] = shift_amt; 
                            shift_unpacked[ i ][ 0 ] = shift_dir;

                            // Iterate through all possible input states
                            repeat( BIT_STATE ) begin
                                #10;
                                in_unpacked[ i ] = in_unpacked[ i ] + 1;
                            end
                        end
                    end
                end
            end

            // Pull down inputs after all test cases are executed
            for( i = 0; i < SETS; i = i + 1 ) begin
                in_unpacked[ i ] = { WIDTH{ 1'b0 } };
                shift_unpacked[ i ] = { WIDTH{ 1'b0 } };
                #10;
            end
        end
    endtask

    initial begin
        $dumpfile( "waveform5.vcd" );
        $dumpvars( 0, tb_mXnShift );

        test_mXnShift;

        $finish;
    end
endmodule