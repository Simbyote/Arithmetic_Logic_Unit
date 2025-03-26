/*
 * combinational_alu.v
 * Purpose:
 * - Contains the modules for the combinational ALU operations
 *
 * Modules Included:
 * - Full_Adder: Controls the flow of the addition operation using combinational logic
 * - Full_Subtractor: Controls the flow of the subtraction operation using combinational logic
 * - Multiplier: Controls the flow of the multiplication operation using combinational logic
 * - Divider: Controls the flow of the division operation using combinational logic
 *
 * Parameters:
 * - WIDTH: The bit-width of the input and output signals
 *
 * Implementation:
 * The "Full_Adder" performs the addition over a generate loop to collect the sum and carry-out bits
 * The "Full_Subtractor" performs the subtraction over a generate loop to collect the difference and borrow-out bits
 * The "Multiplier" performs the multiplication over a generate loop to collect the low and high bits of the product
 * The "Divider" performs the division over a generate loop to collect the quotient and remainder
 */

/*
 * Full_Adder
 *
 * Purpose:
 * - Controls the flow of the addition operation using combinational logic
 *
 * Note:
 * - The addition operation is performed using a generate loop to iterate over the bits
 * - From the "Addition_Core" module, the sum of the current bits are stored in the output
 *   and the carry-out bit is moved to the next bit, unless it is the final bit, to which
 *   it is assigned to the final carry-out bit
 */
module Full_Adder #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out,
    output wire final_carry
);
    // Internal carry wires
    wire [ WIDTH-1:0 ] carry_in, carry_out;
    assign carry_in[ 0 ] = 1'b0;

    genvar i;
    generate
        for( i = 0; i < WIDTH; i = i + 1 ) begin : addition_loop

            // Add the bits and store the outputs
            Addition_Core #( .WIDTH( WIDTH ) ) adder_instance (
                .in1( in1[ i ] ),
                .in2( in2[ i ] ),
                .carry_in( carry_in[ i ] ),
                .out( out[ i ] ),
                .carry_out( carry_out[ i ] )
            );

            // Sets up the next carry or the final carry
            if( i < WIDTH - 1 ) begin
                assign carry_in[ i + 1 ] = carry_out[ i ];
            end
            else begin
                assign final_carry = carry_out[ i ];
            end
        end
    endgenerate
endmodule

/*
 * Full_Subtractor
 * Purpose:
 * - Controls the flow of the subtraction operation using combinational logic
 *
 * Note:
 * - The subtraction operation is performed using a generate loop to iterate over the bits
 * - From the "Subtraction_Core" module, the difference of the current bits are stored in the output
 *   and the borrow-out bit is moved to the next bit, unless it is the final bit, to which
 *   it is assigned to the final borrow-out bit
 */
module Full_Subtractor #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out,
    output wire final_borrow
);
    // Internal borrow wires
    wire [ WIDTH-1:0 ] borrow_in, borrow_out;
    assign borrow_in[ 0 ] = 1'b0;

    genvar i;
    generate
        for( i = 0; i < WIDTH; i = i + 1 ) begin : subtraction_loop
            // Internal output wires
            wire temp_carry_out, temp_out;

            // Subtract the bits and store the outputs
            Subtraction_Core #( .WIDTH( WIDTH ) ) subtractor_instance (
                .in1( in1[ i ] ),
                .in2( in2[ i ] ),
                .borrow_in( borrow_in[ i ] ),
                .out( out[ i ] ),
                .borrow_out( borrow_out[ i ] )
            );

            // Sets up the next borrow or the final borrow
            if( i < WIDTH - 1 ) begin
                assign borrow_in[ i + 1 ] = borrow_out[ i ];
            end
            else begin
                assign final_borrow = borrow_out[ i ];
            end
        end
    endgenerate
endmodule

/*
 * Multiplier
 *
 * Purpose:
 * - Controls the flow of the multiplication operation using combinational logic
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
                .partial_low( partial_high[ i - 1 ] ),
                .partial_high( partial_low[ i - 1 ] ),
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

/*
 * Divider
 * Purpose:
 * - Controls the flow of the division operation using combinational logic
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