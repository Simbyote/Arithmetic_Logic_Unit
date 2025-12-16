`default_nettype none
/*
 * alu_div.v
 * Contains modules for performing division operations on n-bit inputs
 *
 * Purpose:
 * - These modules perform division operations on n-bit inputs
 *
 * Modules Included:
 * - Signal_Decomposition: Deconstructs the input signal into its leading bits and their positions
 * - Signal_Alignment: Aligns two signals based on their leading ones
 * - Divider_Core: Divides two n-bit inputs and provides the quotient, remainder, and flags
 * - Divider: Upper layer datapath for the division operation
 *
 * Parameters:
 * - WIDTH: The bit width of the input-output
 *
 * Implementation:
 * - The `Signal_Decomposition` module deconstructs the input signal into its leading bits and their positions
 * - The `Signal_Alignment` module aligns two signals based on their leading ones
 * - The `Divider_Core` module divides two n-bit inputs and provides the quotient, remainder, and flags
 * - The "Divider" performs the division over a generate loop to collect the quotient and remainder
 */

 /*
 * Signal_Decomposition
 * Purpose: 
 * - Deconstructs the input signal into its leading bits and their positions
 *
 * Note:
 * - Determines the leading bit by comparing with a sample signal that is gradually shifted
 */ 
module Signal_Decomposition #( parameter WIDTH = 4 ) (
    input  wire [ WIDTH-1:0 ] in,
    output wire [ WIDTH-1:0 ] out_lead,
    output wire [ WIDTH-2:0 ] out_pos
);
    // Internal wires
    wire [ WIDTH-1:0 ] greatest_bit[ WIDTH-1:0 ];
    wire [ WIDTH-2:0 ] bit_pos[ WIDTH-1:0 ];
    assign greatest_bit[ 0 ] = in[ 0 ] ? 1'b1 : 1'b0;
    assign bit_pos[ 0 ] = 1'b0;

    genvar i;
    generate
        for( i = 1; i < WIDTH; i = i + 1 ) begin : leading_loop
            // Internal wires
            wire [ WIDTH-2:1 ] shift_amt;
            wire [ WIDTH-1:0 ] shift, shift_result;

            // Build the shift signal
            assign shift_amt = i;
            assign shift = { 1'b0, shift_amt, 1'b0 };

            // Shift a sample signal to compare with the input
            nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shift_instance (
                .in( { { ( WIDTH-1 ){ 1'b0 } }, 1'b1 } ),
                .shift( shift ),
                .out( shift_result ),
                .overflow(  )
            );

            // Assign the greatest bit and mark its position if it is the leading bit
            assign greatest_bit[ i ] = in[ i ] ? shift_result : greatest_bit[ i - 1 ];
            assign bit_pos[ i ] = in[ i ] ? i : bit_pos[ i - 1 ];
        end

        assign out_lead = greatest_bit[ WIDTH - 1 ];
        assign out_pos = bit_pos[ WIDTH - 1 ];
    endgenerate
endmodule

/*
 * Signal_Alignment
 * Purpose: 
 * - Aligns two signals based on their leading ones
 * 
 * Note:
 * - Aligns the divisor with the dividend by shifting the divisor by the difference in positions
 * - Overshoot detection is performed to correct the alignment if the shift is greater than the dividend
 */
module Signal_Alignment #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out,
    output wire [ WIDTH-2:0 ] out_pos
);
    // Internal wires
    wire [ WIDTH-1:0 ] in1_lead, in2_lead, subtractor_result, in2_aligned;
    wire [ WIDTH-2:0 ] in1_pos, in2_pos, temp_pos;
    wire final_borrow;

    // Determine the position of the dividend's leading one
    Signal_Decomposition #( .WIDTH( WIDTH ) ) lead1 (
        .in( in1 ),
        .out_lead( in1_lead ),
        .out_pos( in1_pos )
    );

    // Determine the position of the divisor's leading one
    Signal_Decomposition #( .WIDTH( WIDTH ) ) lead2 (
        .in( in2 ),
        .out_lead( in2_lead ),
        .out_pos( in2_pos )
    );

    // Subtract the positions to determine the shift amount
    Full_Subtractor #( .WIDTH( WIDTH-1 ) ) subtractor_instance (
        .in1( { in1_pos } ),
        .in2( in2_pos ),
        .out( temp_pos ),
        .final_borrow( final_borrow )
    );

    // Shift the divisor to align with the dividend
    nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shift_instance (
        .in( in2 ),
        .shift( { temp_pos, 1'b0 } ),
        .out( in2_aligned ),
        .overflow(  )
    );

    // Overshoot detection wires
    wire overshoot;
    Greater_Than #( .WIDTH( WIDTH ) ) greater_than_instance (
        .in1( in2_aligned ),
        .in2( in1 ),
        .out( overshoot )
    );

    // Corrected alignment wires
    wire [ WIDTH-2:0 ] correct_shift_amt;
    wire [ WIDTH-1:0 ] correct_shift, correct_in2;

    // Assign the corrections
    assign correct_shift_amt = temp_pos - 1;
    assign correct_shift = { 1'b0, correct_shift_amt, 1'b0 };

    // Perform the correction
    nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) correct_shift_instance (
        .in( in2 ),
        .shift( correct_shift ),
        .out( correct_in2 ),
        .overflow(  )
    );

    // Correct the alignment if there is an overshoot, otherwise assign to the aligned divisor
    assign out = overshoot ? correct_in2 : in2_aligned;
    assign out_pos = overshoot ? correct_shift_amt : temp_pos;
endmodule

/*
 * Divider_Core
 * Purpose: 
 * - Divides two n-bit inputs and provides the quotient, remainder, and flags
 * 
 * Note:
 * - The module works in steps to produce its results, starting with the alignment of the dividend and divisor
 *   and then performing the subtraction operation to determine the quotient and remainder
 * - The quotient is assigned based on the how many bits are shifted from the alignment process
 * - The module also checks for special cases such as division by zero, a dividend less than the divisor, and
 *   if there is a final borrow present
 */
module Divider_Core #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out,
    output wire [ WIDTH-1:0 ] remainder,
    output wire is_zero,
    output wire is_less,
    output wire has_borrow
);
    // Internal wires
    wire [ WIDTH-1:0 ] alignment_result;
    wire [ WIDTH-2:0 ] pos;
    wire final_borrow;

    // Align the dividend and divisor
    Signal_Alignment #( .WIDTH( WIDTH ) ) alignment_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( alignment_result ),
        .out_pos( pos )
    );

    // Subtract the aligned divisor from the dividend
    Full_Subtractor #( .WIDTH( WIDTH ) ) initial_subtractor_instance (
        .in1( in1 ),
        .in2( alignment_result ),
        .out( remainder ),
        .final_borrow( final_borrow )
    );

    // Assign the quotient based on the current position being worked on
    nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shift_quotient_instance (
        .in( { {(WIDTH-1){1'b0}}, 1'b1 } ),
        .shift( { pos, 1'b0 } ),
        .out( out ),
        .overflow(  )   // Overflow is not used
    );

    // Check if the divisor is zero
    Equal_To #( .WIDTH( WIDTH ) ) equal_instance (
        .in1( in2 ),
        .in2( { WIDTH{ 1'b0 } } ),
        .out( is_zero )
    );

    // Check if in1 < in2
    Less_Than #( .WIDTH( WIDTH ) ) less_than_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( is_less )
    );

    // Check if there is a final borrow
    Equal_To #( .WIDTH( 1 ) ) final_borrow_instance (
        .in1( final_borrow ),
        .in2( 1'b0 ),
        .out( has_borrow )
    );
endmodule

/*
 * Divider
 * Purpose:
 * - Datapath of the division operation utilizing the Divider_Core module
 *
 * Note:
 * - The division operation is performed using a generate loop to iterate over the bits
 * - From the "Divider_Core" module, the quotient of the current bits are stored in the output
 *   and the remainder is moved to the next bit, unless it is the final bit, to which
 *   it is assigned to the final remainder
 * - Using flags from the "Divider_Core" module, the module assigns the correct values to the quotient and remainder
 */
module Divider #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out,
    output wire [ WIDTH-1:0 ] remainder
);
    // Collects the partial quotients and remainders
    wire [ WIDTH-1:0 ] partial_quotient[ WIDTH-1:0 ];
    wire [ WIDTH-1:0 ] partial_remainder[ WIDTH-1:0 ];

    // Internal wires
    wire [ WIDTH-1:0 ] quotient_result, remainder_result;
    wire is_zero, is_less, has_borrow;

    // Perform the division operation 
    Divider_Core #( .WIDTH( WIDTH ) ) divider_core_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( quotient_result ),
        .remainder( remainder_result ),
        .is_zero( is_zero ),
        .is_less( is_less ),
        .has_borrow( has_borrow )
    );

    // Assign the quotient to the shifted position if subtraction is valid
    assign partial_quotient[ 0 ] = has_borrow
                                && !is_zero
                                && !is_less
                                ? quotient_result : { WIDTH{ 1'b0 } };
    // Set the shift result as the initial remainder if subtraction is valid
    assign partial_remainder[ 0 ] = is_zero
                              ? { WIDTH{ 1'b0 } } 
                              : ( has_borrow 
                                && !is_less 
                                ? remainder_result : in1 );
    genvar i;
    generate
        for( i = 1; i < WIDTH; i = i + 1 ) begin : division_loop
            // Internal wires
            wire [ WIDTH-1:0 ] temp_quotient_result, temp_remainder_result;
            wire temp_is_less, temp_has_borrow;

            // Perform the division operation
            Divider_Core #( .WIDTH( WIDTH ) ) divider_core_loop_instance (
                .in1( partial_remainder[ i - 1 ] ),
                .in2( in2 ),
                .out( temp_quotient_result ),
                .remainder( temp_remainder_result ),
                .is_zero( is_zero ),
                .is_less( temp_is_less ),
                .has_borrow( temp_has_borrow )
            );

            // Assign the quotient and remainder based on the flags
            assign partial_quotient[ i ] = temp_has_borrow 
                                        && !is_zero 
                                        && !temp_is_less 
                                        ? partial_quotient[ i - 1 ] + temp_quotient_result 
                                        : partial_quotient[ i - 1 ];

            // Assign the remainder based on the flags
            assign partial_remainder[ i ] = temp_has_borrow 
                                        && !is_zero 
                                        && !temp_is_less 
                                        ? temp_remainder_result 
                                        : partial_remainder[ i - 1 ];
        end
    endgenerate

    assign out = partial_quotient[ WIDTH - 1 ];
    assign remainder = partial_remainder[ WIDTH - 1 ];
endmodule