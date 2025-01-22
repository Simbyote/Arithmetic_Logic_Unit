/*
 * testbench_mXnShift.v
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
module testbench_mXnShift;
    parameter WIDTH = 4;
    parameter BIT_STATE = 2 ** WIDTH;
    parameter SETS = 2;

    /*
     * Input signals & unique output signals for each mXnBit shift module
     */
    wire [ SETS*WIDTH-1:0 ] in_packed;
    wire [ SETS*WIDTH-1:0 ] out_packed_logical, out_packed_arithmetic;

    /*
     * Instantiate the mXnBits_Shift module for logical and arithmetic shifts
     */
    mXnBits_Shift #( .WIDTH( WIDTH ), .SETS( SETS ), .OP( 0 ) ) shift_logical(
        .in_packed( in_packed ),
        .shift_dir( shift_dir ),
        .shift_amt( shift_amt ),
        .out_packed( out_packed_logical )
    );

    mXnBits_Shift #( .WIDTH( WIDTH ), .SETS( SETS ), .OP( 1 ) ) shift_arithmetic(
        .in_packed( in_packed ),
        .shift_dir( shift_dir ),
        .shift_amt( shift_amt ),
        .out_packed( out_packed_arithmetic )
    );

    // Unpacked inputs and unique outputs for type of shift
    reg [ WIDTH-1:0 ] in_unpacked [ SETS-1:0 ];
    reg shift_dir;
    reg [ WIDTH-1:0 ] shift_amt;
    wire [ WIDTH-1:0 ] out_unpacked_logical [ SETS-1:0 ];
    wire [ WIDTH-1:0 ] out_unpacked_arithmetic [ SETS-1:0 ];

    // Unpack the inputs
    genvar i;
    generate
        for( i = 0; i < SETS; i = i + 1 ) begin : unpack_inputs
            assign in_packed[ i*WIDTH +: WIDTH ] = in_unpacked[ i ];
        end
    endgenerate

    /*
     * Tests the inputs that each shift module can receive
     * The test iterates through all possible input values and shift amounts
     * for both logical and arithmetic shift operations
     */
    task test_mXnShift;
        integer MAX_SHIFT;
        integer idx;

        begin
            // Initialize the inputs
            shift_dir = 0;
            for( idx = 0; idx < SETS; idx = idx + 1 ) begin
                in_unpacked[ idx ] = { WIDTH{ 1'b0 } };
            end

            // Iterate through shift directions
            repeat ( 2 ) begin
                // Determine maximum shift amount based on direction
                if (shift_dir == 0)
                    MAX_SHIFT = WIDTH - 1;    // Left shift
                else
                    MAX_SHIFT = (WIDTH / 2);  // Right shift

                shift_amt = 1;
                // Iterate through shift amounts
                repeat ( MAX_SHIFT ) begin

                    // Initialize the input value
                    for( idx = 0; idx < SETS; idx = idx + 1 ) begin
                        in_unpacked[ idx ] = { WIDTH{ 1'b0 } };
                    end

                    // Iterate through all input values
                    repeat ( BIT_STATE ) begin
                        #10;
                        for( idx = 0; idx < SETS; idx = idx + 1 ) begin
                            in_unpacked[ idx ] = in_unpacked[ idx ] + 1;
                        end
                    end
                    shift_amt = shift_amt + 1;
                end

                // Switch to the next shift direction
                shift_dir = shift_dir + 1;
            end

            // Pull inputs low after all test cases are executed
            for( idx = 0; idx < SETS; idx = idx + 1 ) begin
                in_unpacked[ idx ] = { WIDTH{ 1'b0 } };
            end
        end
    endtask

    initial begin
        $dumpfile( "waveform5.vcd" );
        $dumpvars( 0, testbench_mXnShift );

        test_mXnShift;

        $finish;
    end
endmodule