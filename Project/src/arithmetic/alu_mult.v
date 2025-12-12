/*
 * alu_mult.v
 * Contains modules for performing multiplication on n-bit inputs
 *
 * Purpose:
 * - These modules perform multiplication on n-bit inputs
 * 
 * Modules Included:
 * - Multiplier_Core: Performs the multiplication operation on two n-bit inputs
 * - Multiplier: Upper layer datapath for the multiplication operation
 *
 * Parameters:
 * - WIDTH: The bit width of the input-output
 *
 * Implementation:
 * - The `Multiplier_Core` module performs the multiplication operation on two n-bit inputs
 * - The "Multiplier" performs the multiplication over a generate loop to collect the low and high bits of the product
 */

/*
 * Multiplier_Core
 *
 * Purpose:
 * - Performs the multiplication operation on two n-bit inputs
 *
 * Note:
 * - The module uses two output types: the outputs and a flag
 * - The Full_Adder modules calculate the sum while the Equal_To module determines the flag
 * - Meant to be used in a loop for n-bit multiplication
 * - Typically, this module would start with a partial sum of 0 and have its step_counter set 
 *   to 0 for the first bit and would be updated over the course of the multiplication operation 
 *   until a final sum is determined
 */
module Multiplier_Core #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    input wire [ WIDTH-1:0 ] partial_high,
    input wire [ WIDTH-1:0 ] partial_low,
    input wire [ WIDTH-2:0 ] step_counter,
    output wire [ WIDTH-1:0 ] out_high,
    output wire [ WIDTH-1:0 ] out_low,
    output wire is_equal
);
    // Internal wires
    wire [ WIDTH-1:0 ] shift, shift_result, shift_overflow, combined_overflow;
    wire final_carry;
    assign shift = { step_counter, 1'b0 };  // Contruct the shift signal

    // Shift the multiplicand according to the step
    nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shift_instance (
        .in( in1 ),
        .shift( shift ),
        .out( shift_result ),
        .overflow( shift_overflow )
    );

    // Add the shifted multiplicand to the low side of the partial sum
    Full_Adder #( .WIDTH( WIDTH ) ) adder_low_instance (
        .in1( partial_low ),
        .in2( shift_result ),
        .out( out_low ),
        .final_carry( final_carry )
    );

    // Add the overflow from the shift to the high side of the partial sum
    Full_Adder #( .WIDTH( WIDTH ) ) adder_overflow_instance (
        .in1( partial_high ),
        .in2( shift_overflow ),
        .out( combined_overflow ),
        .final_carry(  )
    );

    // Add the overflow from the two addition operations to the high side of the partial sum
    Full_Adder #( .WIDTH( WIDTH ) ) adder_final_instance (
        .in1( combined_overflow ),
        .in2( { { ( WIDTH-1 ){ 1'b0 } }, final_carry } ),
        .out( out_high ),
        .final_carry(  )    // Final carry is not used
    );

    // Determine if the current bit being calculated is is equal to 1
    Equal_To #( .WIDTH( 1 ) ) equal_instance (
        .in1( in2[ step_counter ] ),
        .in2( 1'b1 ),
        .out( is_equal )
    );
endmodule

/*
 * Multiplier
 *
 * Purpose:
 * - Datapath of the multiplication operation utilizing the Multiplier_Core module
 *
 * Note:
 * - The multiplication operation is performed using a generate loop to iterate over the bits
 * - From the "Multiplier_Core" module, the sum of the current bits are stored in the output
 *   and the carry-out bit is moved to the next bit, unless it is the final bit, to which
 *   it is assigned to the final carry-out bit
 * - Utilizes a flag to assign correct values to the partial sums
 */
module Multiplier #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out_low,
    output wire [ WIDTH-1:0 ] out_high
);
    // Internal wires
    wire [ WIDTH-1:0 ] partial_low[ WIDTH-1:0 ];
    wire [ WIDTH-1:0 ] partial_high[ WIDTH-1:0 ];

    // Assign the initial values for the high and low sums
    assign partial_low[ 0 ] = in2[ 0 ] ? in1 : { WIDTH{ 1'b0 } };
    assign partial_high[ 0 ] = { WIDTH{ 1'b0 } };

    genvar i;
    generate
        for( i = 1; i < WIDTH; i = i + 1 ) begin : multiplication_loop
            // Internal wires
            wire [ WIDTH-1:0 ] temp_low, temp_high;
            wire [ WIDTH-2:0 ] pos;
            wire is_equal;
            assign pos = i; // Assign the current position
            
            // Perform the multiplication operation
            Multiplier_Core #( .WIDTH( WIDTH ) ) multiplier_core_instance (
                .in1( in1 ),
                .in2( in2 ),
                .partial_high( partial_high[ i - 1 ] ),
                .partial_low( partial_low[ i - 1 ] ),
                .step_counter( pos ),
                .out_high( temp_high ),
                .out_low( temp_low ),
                .is_equal( is_equal )
            );

            // Assign the correct outputs to the partial sums
            assign partial_low[ i ] = is_equal ? temp_low : partial_low[ i - 1 ];
            assign partial_high[ i ] = is_equal ? temp_high : partial_high[ i - 1 ];
        end 
    endgenerate

    assign out_low = partial_low[ WIDTH - 1 ];
    assign out_high = partial_high[ WIDTH - 1 ];
endmodule