/*
 * arithmetic_operations.v
 * Contains modules for performing arithmetic operations on n-bit inputs
 *
 * Purpose:
 * - These modules perform arithmetic operations on mXn-bit inputs or n-bit inputs
 *
 * Modules Included:
 * - UnpackPack_Shift: Unpacks a packed input, applies a shift operation, and packs the shifted outputs
 * - nBit_Shift: Performs an arithmetic shift (left or right) on an n-bit input
 * - mXnBits_Shift: Performs a shift operation on a packed input of mxn bits
 *
 * Parameters:
 * - WIDTH: The bit width of the input-output
 * - OP: The logical operation to perform 
 * - SETS: The number of sets of n-bit inputs to process
 *
 * Implementation:
 * - The `UnpackPack_Shift` module provides a generalized framework to unpack
 *   packed inputs, perform the desired shift operation, and repack the outputs
 * - The `nBit_Shift` module performs an arithmetic shift operation on an n-bit input
 * - The `mXnBits_Shift` module performs a shift operation on a packed input of mxn bits
 */

/*
 * UnpackPack_Shift
 * Unpacks a packed input into individual n-bit inputs, applies a shift operation
 * to each input, and then packs the shifted outputs back into a single packed output
 * based on a specified shift direction and amount
 *
 * Purpose:
 * - Unpacks a packed input into individual n-bit inputs
 * - Applies a shift operation to each unpacked input
 * - Packs the shifted outputs back into a single packed output
 */
module UnpackPack_Shift #( parameter WIDTH = 4, parameter SETS = 2, parameter OP = 0 ) (
input wire [ SETS*WIDTH-1:0 ] in_packed,
    input wire [ SETS*WIDTH-1:0 ] shift_packed,
    output wire [ SETS*WIDTH-1:0 ] out_packed,
    output wire [ SETS*WIDTH-1:0 ] overflow_packed
);
    // Internal wires for unpacked inputs and outputs
    wire [ WIDTH-1:0 ] in_unpacked [ SETS-1:0 ];
    wire [ WIDTH-1:0 ] shift_unpacked [ SETS-1:0 ];
    wire [ WIDTH-1:0 ] out_unpacked [ SETS-1:0 ];
    wire [ WIDTH-1:0 ] overflow_unpacked [ SETS-1:0 ];

    genvar i;
    generate
        // Unpack the pcaked inputs into individual sets
        for( i = 0; i < SETS; i = i + 1 ) begin : unpack_inputs
            assign in_unpacked[ i ] = in_packed[ i*WIDTH +: WIDTH ];
            assign shift_unpacked[ i ] = shift_packed[ i*WIDTH +: WIDTH ];
        end

        // Apply the shift operation to each unpacked input
        for( i = 0; i < SETS; i = i + 1 ) begin : shift_operation
            nBit_Shift #( .WIDTH( WIDTH ), .OP( OP ) ) shift(
                .in( in_unpacked[ i ] ),
                .shift( shift_unpacked[ i ] ),
                .out( out_unpacked[ i ] ),
                .overflow( overflow_unpacked[ i ] )
            );
        end

        // Pack the shifted outputs
        for( i = 0; i < SETS; i = i + 1 ) begin : pack_outputs
            assign out_packed[ i*WIDTH +: WIDTH ] = out_unpacked[ i ];
            assign overflow_packed[ i*WIDTH +: WIDTH ] = overflow_unpacked[ i ];
        end
    endgenerate
endmodule

/*
 * nBit_Shift
 *
 * Purpose:
 * - Performs an arithmetic shift (left or right) on an n-bit input
 *   based on a specified shift direction and amount
 *
 * Logical Shift ----
 * - Left shift: 0 = 0001 << 1 = 0010
 * - Right shift: 0 = 0001 >> 1 = 0000
 *
 * Arithmetic Shift ---- 
 * - Left shift: 0 = 0001 << 1 = 0010
 * - Right shift: 0 = 0001 >>> 1 = 0000 (or)
 * - Right shift: 1 = 1000 >>> 1 = 1100
 *
 * Note:
 * - Logical shift fills the shifted-in bits with 0
 * - Arithmetic shift fills the shifted-in bits with the sign bit (MSB)
 * - Shifts bits in binary numbers either left or right
 */
module nBit_Shift #( parameter WIDTH = 4, parameter OP = 0 ) (
    input wire [ WIDTH-1:0 ] in,
    input wire [ WIDTH-1:0 ] shift,
    output reg [ WIDTH-1:0 ] out,
    output reg [ WIDTH-1:0 ] overflow
);
    // Compile-time check for invalid WIDTH and OP
    generate
        if( WIDTH < 2 ) begin
            initial begin
                $error( "WIDTH must be at least 2" );
            end
        end
        else if( OP < 0 || OP > 1 ) begin
            initial begin
                $error( "OP must be between 0 or 1" );
            end
        end
    endgenerate
    
    // Internal wires
    wire shift_dir = shift[ 0 ];  // LSB determines the shift direction
    wire [ WIDTH-2:0 ] shift_amt = shift[ WIDTH-2:1 ]; // Remaining bits determine the shift amount
    wire fill = shift[ WIDTH-1 ];    // MSB determines the fill value

    // Perform the shift operation
    always @(*) begin
        // Default values
        out = { WIDTH{ 1'b0 } };
        overflow = { WIDTH{ 1'b0 } };

        if( OP == 0 ) begin // Logical shift
            if( shift_dir == 1'b0 ) begin   // Left shift
                out = ( in << shift_amt ) | ( fill << ( shift_amt - 1 ) );
                overflow = in >> ( WIDTH - shift_amt );
            end
            else begin  // Right shift
                out = ( in >> shift_amt ) | ( fill << ( WIDTH - shift_amt ) );
                overflow = in & ( ( 1 << shift_amt ) - 1 );
            end
        end
        else if( OP == 1 ) begin    // Arithmetic shift
                if( shift_dir == 1'b0 ) begin   // Left shift
                    out = in << shift_amt;
                    overflow = in >> ( WIDTH - shift_amt );
                end     // Right shift
                else begin
                    out = $signed( in ) >>> shift_amt;
                    overflow = in & ( ( 1 << shift_amt ) - 1 );
                end
        end
        else begin
                $error( "Error: Default case succeeded where it shouldn't. \n" );
        end
    end
endmodule

/*
 * mXnBits_Shift
 *
 * Purpose:
 * - Performs a shift operation on a packed input of mxn bits
 *   based on a specified shift direction and amount
 */
module mXnBits_Shift #( parameter WIDTH = 4, parameter SETS = 2, parameter OP = 0) (
    input wire [ SETS*WIDTH-1:0 ] in_packed,
    input wire [ SETS*WIDTH-1:0 ] shift_packed,
    output wire [ SETS*WIDTH-1:0 ] out_packed,
    output wire [ SETS*WIDTH-1:0 ] overflow_packed
);
    // Check for invalid SETS
    Set_Check #( .SETS( SETS ) ) set_check( );

    // Generate the shift operation based on the specified OP
    generate
        if( OP == 0 ) begin
            // Unpack, shift logically, and pack the inputs and outputs
            UnpackPack_Shift #( .WIDTH( WIDTH ), .SETS( SETS ), .OP( 0 ) ) shift_logical(
                .in_packed( in_packed ),
                .shift_packed( shift_packed ),
                .out_packed( out_packed ),
                .overflow_packed( overflow_packed )
            ); 
        end
        else if( OP == 1 ) begin
            // Unpack, shift arithmetically, and pack the inputs and outputs
            UnpackPack_Shift #( .WIDTH( WIDTH ), .SETS( SETS ), .OP( 1 ) ) shift_arithmetic(
                .in_packed( in_packed ),
                .shift_packed( shift_packed ),
                .out_packed( out_packed ),
                .overflow_packed( overflow_packed )
            );
        end
    endgenerate
endmodule

module Less_Than #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire out
);
    // Internal subtractor wires
    wire [ WIDTH-1:0 ] subtractor_result;
    wire final_borrow;

    // Subtract the inputs and assign the final borrow to the output
    Full_Subtractor #( .WIDTH( WIDTH ) ) subtractor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( subtractor_result ),
        .final_borrow( out )
    );
endmodule

module Greater_Than #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire  out
);
    // Internal wires
    wire [ WIDTH-1:0 ] is_less_than_result;

    // Determine if in2 is less than in1 and assign the result to the output
    Less_Than #( .WIDTH( WIDTH ) ) less_than_instance (
        .in1( in2 ),
        .in2( in1 ),
        .out( out )
    );
endmodule

module Equal_To #( parameter WIDTH = 4) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire out
);
    // Internal wires
    wire less_than_result, greater_than_result; 
    wire final_borrow;

    // Determine if in1 is less than in2
    Less_Than #( .WIDTH( WIDTH ) ) less_than_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( less_than_result )
    );

    // Determine if in1 is greater than in2
    Greater_Than #( .WIDTH( WIDTH ) ) greater_than_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( greater_than_result )
    );

    // Determine if in1 is equal to in2
    NOR and_instance (
        .in1( less_than_result ),
        .in2( greater_than_result ),
        .out( out )
    );    
endmodule

// 1-bit Half Adder
module Half_Adder (
    input wire in1,
    input wire in2,
    output wire out,
    output wire carry_out
);
    // Determines the sum
    XOR xor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( out )
    );

    // Determines the carry
    AND and_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( carry_out )
    );
endmodule

// nBit Full Adder ( in1 + in2 )
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
            // Internal output wires
            wire temp_carry_out, temp_out;

            // Add the inputs and store the output
            Half_Adder half_adder_instance1 (
                .in1( in1[ i ] ),
                .in2( in2[ i ] ),
                .out( temp_out ),
                .carry_out( temp_carry_out )
            );

            // Add the carry
            Half_Adder half_adder_instance2 (
                .in1( temp_out ),
                .in2( carry_in[ i ] ),
                .out( out[ i ] ),
                .carry_out( carry_out[ i ] )
            );

            // Assign the carry to the next bit
            if( i < WIDTH - 1 ) begin
                OR or_instance (
                    .in1( carry_out[ i ] ),
                    .in2( temp_carry_out ),
                    .out( carry_in[ i + 1 ] )
                );
            end
            else begin
                OR or_instance (
                    .in1( carry_out[ i ] ),
                    .in2( temp_carry_out ),
                    .out( final_carry )
                );
            end
        end
    endgenerate
endmodule

// 1-bit half subtractor
module Half_Subtractor (
    input wire in1,
    input wire in2,
    output wire out,
    output wire borrow_out
);
    // Determines the difference
    XOR xor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( out )
    );

    // Inverts the subtractor input
    NOT not_instance (
        .in( in1 ),
        .out( in1_not )
    );

    // Determines the borrow
    AND and_instance (
        .in1( in1_not ),
        .in2( in2 ),
        .out( borrow_out )
    );
endmodule

// nBit Subtractor ( in1 - in2 )
module Full_Subtractor #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out,
    output wire final_borrow
);
    // Internal borrow wires
    wire [ WIDTH-1:0 ] borrow_in, borrow_out, out_assign;
    assign borrow_in[ 0 ] = 1'b0;

    genvar i;
    generate
        for( i = 0; i < WIDTH; i = i + 1 ) begin : subtraction_loop
            // Internal output wires
            wire temp_carry_out, temp_out;

            // Subtract the inputs and store the output
            Half_Subtractor half_subtractor_instance1 (
                .in1( in1[ i ] ),
                .in2( in2[ i ] ),
                .out( temp_out ),
                .borrow_out( temp_carry_out )
            );

            // Subtract the borrow
            Half_Subtractor half_subtractor_instance2 (
                .in1( temp_out ),
                .in2( borrow_in[ i ] ),
                .out( out_assign[ i ] ),
                .borrow_out( borrow_out[ i ] )
            );

            // Assign the borrow to the next bit
            if( i < WIDTH - 1 ) begin
                OR or_instance (
                    .in1( borrow_out[ i ] ),
                    .in2( temp_carry_out ),
                    .out( borrow_in[ i + 1 ] )
                );
            end
            else begin
                OR or_instance (
                    .in1( borrow_out[ i ] ),
                    .in2( temp_carry_out ),
                    .out( final_borrow )
                );
            end

            assign out[ i ] = final_borrow ? 1'b0 : out_assign[ i ];
        end
    endgenerate
endmodule

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
            wire [ WIDTH-1:0 ] temp_low, temp_high_overflow, temp_high_carry, temp_overflow;
            wire [ WIDTH-1:0 ] shift, shift_result;
            wire [ WIDTH-2:0 ] shift_amt;
            wire final_carry;

            assign shift_amt = $unsigned(i) << 1;
            assign shift = { shift_amt, 1'b0 };

            // Shift the multiplicand by the current loop index
            nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shift_instance (
                .in( in1 ),
                .shift( shift ),
                .out( shift_result ),
                .overflow( temp_overflow )
            );

            // Add the low output to the shifted multiplicand
            Full_Adder #( .WIDTH( WIDTH ) ) adder_low_instance (
                .in1( partial_low[ i - 1 ] ),
                .in2( shift_result ),
                .out( temp_low ),
                .final_carry( final_carry )
            );

            // Add the high output to the overflow
            Full_Adder #( .WIDTH( WIDTH ) ) adder_overflow_instance (
                .in1( partial_high[ i - 1 ] ),
                .in2( temp_overflow ),
                .out( temp_high_overflow ),
                .final_carry(  )
            );

            // Add the carry from the low output to the high output
            Full_Adder #( .WIDTH( WIDTH ) ) adder_final_instance (
                .in1( temp_high_overflow ),
                .in2( { { ( WIDTH-1 ){ 1'b0 } }, final_carry } ),
                .out( temp_high_carry ),
                .final_carry(  )
            );

            // Assign the respective outputs to the partial sums
            assign partial_low[ i ] = in2[ i ] ? temp_low : partial_low[ i - 1 ];
            assign partial_high[ i ] = in2[ i ] ? temp_high_carry : partial_high[ i - 1 ];
        end

        assign out_low = partial_low[ WIDTH - 1 ];
        assign out_high = partial_high[ WIDTH - 1 ];
    endgenerate
endmodule

module Division_Decomposition #( parameter WIDTH = 4 ) (
    input  wire [ WIDTH-1:0 ] in,
    output wire [ WIDTH-1:0 ] out_lead,
    output wire [ WIDTH-2:0 ] out_pos
);
    wire [ WIDTH-1:0 ] greatest_bit[ WIDTH-1:0 ];
    wire [ WIDTH-2:0 ] bit_pos[ WIDTH-1:0 ];
    assign greatest_bit[ 0 ] = in[ 0 ] ? 1'b1 : 1'b0;
    assign bit_pos[ 0 ] = 1'b0;

    genvar i;
    generate
        for( i = 1; i < WIDTH; i = i + 1 ) begin : leading_loop
            wire [ WIDTH-2:1 ] shift_amt;
            wire [ WIDTH-1:0 ] shift, shift_result;
            assign shift_amt = i;
            assign shift = { 1'b0, shift_amt, 1'b0 };
            nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shift_instance (
                .in( { { ( WIDTH-1 ){ 1'b0 } }, 1'b1 } ),
                .shift( shift ),
                .out( shift_result ),
                .overflow(  )
            );

           assign greatest_bit[ i ] = in[ i ] ? shift_result : greatest_bit[ i - 1 ];
           assign bit_pos[ i ] = in[ i ] ? i : bit_pos[ i - 1 ];
        end

        assign out_lead = greatest_bit[ WIDTH - 1 ];
        assign out_pos = bit_pos[ WIDTH - 1 ];
    endgenerate
endmodule

module Division_Alignment #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out,
    output wire [ WIDTH-2:0 ] out_pos
);
    // Internal wires
    wire [ WIDTH-1:0 ] in1_lead, in2_lead;
    wire [ WIDTH-2:0 ] in1_pos, in2_pos;

    wire [ WIDTH-2:0 ] temp_pos;

    wire [ WIDTH-1:0 ] subtractor_result;
    wire final_borrow;

    wire [ WIDTH-1:0 ] aligned_in2;

    // Determine the position of the dividend's leading one
    Division_Decomposition #( .WIDTH( WIDTH ) ) lead1 (
        .in( in1 ),
        .out_lead( in1_lead ),
        .out_pos( in1_pos )
    );

    // Determine the position of the divisor's leading one
    Division_Decomposition #( .WIDTH( WIDTH ) ) lead2 (
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
        .out( aligned_in2 ),
        .overflow(  )
    );

    wire overshoot = ( aligned_in2 > in1 );

    wire [ WIDTH-2:0 ] correct_shift_amt = temp_pos - 1;
    wire [ WIDTH-1:0 ] correct_shift = { 1'b0, correct_shift_amt, 1'b0 };
    wire [ WIDTH-1:0 ] correct_aligned_in2;

    nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) correct_shift_instance (
        .in( in2 ),
        .shift( correct_shift ),
        .out( correct_aligned_in2 ),
        .overflow(  )
    );

    assign out = overshoot ? correct_aligned_in2 : aligned_in2;
    assign out_pos = overshoot ? correct_shift_amt : temp_pos;
endmodule

module Divider #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out,
    output wire [ WIDTH-1:0 ] remainder
);
    wire [ WIDTH-1:0 ] expected_quotient;
    assign expected_quotient = in2 != 0 ? in1 / in2 : { WIDTH{ 1'b0 } };

    wire [ WIDTH-1:0 ] partial_quotient[ WIDTH-1:0 ];
    wire [ WIDTH-1:0 ] partial_remainder[ WIDTH-1:0 ];

    wire [ WIDTH-1:0 ] in2_aligned;
    wire [ WIDTH-2:0 ] pos;

    // This subtractor uses the shift result to subtract from 'in1'
    wire [ WIDTH-1:0 ] subtractor_result;
    wire final_borrow;

    // High is yes, low is no
    wire perform_subtraction; 

    // Sets the quotient
    wire [ WIDTH-1:0 ] set_quotient;

    // Align 'in2' with 'in1' based on leading bits
    Division_Alignment #( .WIDTH( WIDTH ) ) alignment_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( in2_aligned ),
        .out_pos( pos )
    );

    // Subtract the aligned 'in2' from 'in1' to get the initial remainder
    Full_Subtractor #( .WIDTH( WIDTH ) ) initial_subtractor_instance (
        .in1( in1 ),
        .in2( in2_aligned ),
        .out( subtractor_result ),
        .final_borrow( final_borrow )
    );


    assign perform_subtraction = final_borrow ? 1'b0 : 1'b1;

    // For the quotient, align the first bit based on what the shift amount was and place it there in the quotient
    nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shift_quotient_instance (
        .in( { {(WIDTH-1){1'b0}}, 1'b1 } ),
        .shift( { pos, 1'b0 } ),
        .out( set_quotient ),
        .overflow(  )
    );

    wire zero = ( in2 == 0 );
    wire less_than = ( in1 < in2 );

    
    // Assign the quotient to the shifted position if subtraction is valid
    assign partial_quotient[ 0 ] = perform_subtraction
                                && !zero
                                && !less_than
                                ? set_quotient 
                                : { WIDTH{ 1'b0 } };
    // Set the shift result as the initial remainder if subtraction is valid
    assign partial_remainder[0] = zero
                              ? { WIDTH{ 1'b0 } } 
                              : ( perform_subtraction && !less_than 
                                 ? subtractor_result 
                                 : in1 );


    genvar i;
    generate
        for( i = 1; i < WIDTH; i = i + 1 ) begin : division_loop

            wire [ WIDTH-1:0 ] new_quotion_check, new_remainder_check;

            wire [ WIDTH-1:0 ] new_aligned_in1;
            wire [ WIDTH-2:0 ] new_pos;

            wire [ WIDTH-1:0 ] new_subtractor_result;
            wire new_final_borrow;

            wire new_performance_subtraction;

            wire [ WIDTH-1:0 ] new_set_quotient;

            Division_Alignment #( .WIDTH( WIDTH ) ) new_alignment_instance (
                .in1( partial_remainder[ i - 1 ] ),
                .in2( in2 ),
                .out( new_aligned_in1 ),
                .out_pos( new_pos )
            );

            Full_Subtractor #( .WIDTH( WIDTH ) ) new_subtractor_instance (
                .in1( partial_remainder[ i - 1 ] ),
                .in2( new_aligned_in1 ),
                .out( new_subtractor_result ),
                .final_borrow( new_final_borrow )
            );

            assign new_performance_subtraction = new_final_borrow ? 1'b0 : 1'b1;

            nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) new_shift_quotient_instance (
                .in( { {(WIDTH-1){1'b0}}, 1'b1 } ),
                .shift( { new_pos, 1'b0 } ),
                .out( new_set_quotient ),
                .overflow(  )
            );

            wire divisor_check = ( partial_remainder[ i - 1 ] < in2 );

            assign partial_quotient[ i ] = new_performance_subtraction 
                                        && !zero 
                                        && !divisor_check 
                                        ? partial_quotient[ i - 1 ] + new_set_quotient 
                                        : partial_quotient[ i - 1 ];

            assign partial_remainder[ i ] = new_performance_subtraction 
                                        && !zero 
                                        && !divisor_check 
                                        ? new_subtractor_result 
                                        : partial_remainder[ i - 1 ];
        end

        assign out = partial_quotient[ WIDTH - 1 ];
        assign remainder = partial_remainder[ WIDTH - 1 ];
    endgenerate
endmodule