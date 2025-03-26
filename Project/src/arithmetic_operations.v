/*
 * arithmetic_operations.v
 * Contains modules for performing arithmetic operations on n-bit inputs
 *
 * Purpose:
 * - These modules perform arithmetic operations on n-bit inputs
 *
 * Modules Included:
 * - UnpackPack_Shift: Unpacks a packed input, applies a shift operation, and packs the shifted outputs
 * - mXnBits_Shift: Performs a shift operation on a packed input of mxn bits
 * - nBit_Shift: Performs an arithmetic shift (left or right) on an n-bit input
 *
 * - Half_Adder: Performs addition on two 1-bit inputs and provides their sum and carry
 * - Addition_Core: Performs addition on two 1-bit inputs and the carry bits
 *
 * - Half_Subtractor: Performs subtraction on two 1-bit inputs and provides their difference and borrow
 * - Subtraction_Core: Performs subtraction on two 1-bit inputs and the borrow bits
 *
 * - Less_Than: Determines if the first n-bit input is less than the second n-bit input
 * - Greater_Than: Determines if the first n-bit input is greater than the second n-bit input
 * - Equal_To: Determines if the first n-bit input is equal to the second n-bit input
 *
 * - Multiplier_Core: Performs the multiplication operation on two n-bit inputs
 *
 * - Signal_Decomposition: Deconstructs the input signal into its leading bits and their positions
 * - Signal_Alignment: Aligns two signals based on their leading ones
 * - Divider_Core: Divides two n-bit inputs and provides the quotient, remainder, and flags
 *
 * Parameters:
 * - WIDTH: The bit width of the input-output
 * - OP: The logical operation to perform 
 * - SETS: The number of sets of n-bit inputs to process
 *
 * Implementation:
 * - The `UnpackPack_Shift` module provides a generalized framework to unpack
 *   packed inputs, perform the desired shift operation, and repack the outputs
 * - The `mXnBits_Shift` module performs a shift operation on a packed input of mxn bits
 * - The `nBit_Shift` module performs an arithmetic shift operation on an n-bit input

 * - The `Half_Adder` module performs addition on two 1-bit inputs and provides their sum and carry
 * - The `Addition_Core` module performs addition on two 1-bit inputs and the carry bits
 * - The `Full_Adder` module controls the flow of the addition operation using combinational logic

 * - The `Half_Subtractor` module performs subtraction on two 1-bit inputs and provides their difference and borrow
 * - The `Subtraction_Core` module performs subtraction on two 1-bit inputs and the borrow bits
 * - The `Full_Subtractor` module controls the flow of the subtraction operation using combinational logic

 * - The `Less_Than` module determines if the first n-bit input is less than the second n-bit input
 * - The `Greater_Than` module determines if the first n-bit input is greater than the second n-bit input
 * - The `Equal_To` module determines if the first n-bit input is equal to the second n-bit input

 * - The `Multiplier_Core` module performs the multiplication operation on two n-bit inputs
 * - The `Multiplier` module controls the flow of the multiplication operation using combinational logic

 * - The `Signal_Decomposition` module deconstructs the input signal into its leading bits and their positions
 * - The `Signal_Alignment` module aligns two signals based on their leading ones
 * - The `Divider_Core` module divides two n-bit inputs and provides the quotient, remainder, and flags
 * - The `Divider` module controls the flow of the division operation using combinational logic
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

/*
 * nBit_Shift
 *
 * Purpose:
 * - Performs an arithmetic shift (left or right) on an n-bit input
 *   based on a specified shift direction and amount
 * - Supports logical and arithmetic shift operations
 *
 * Note:
 * - OP value of 0 commences a logical shift; it fills the shifted-in bits with 0
 * - OP value of 1 commences an arithmetic shift; it fills the shifted-in bits with the sign bit (MSB)
 * - The shift can be decomposed into parts as direction, amount, and fill value
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
 * Half_Adder
 *
 * Purpose:
 * - Performs addition on two 1-bit inputs and provides their sum and carry
 *
 * Note:
 * - The sum is the XOR of the inputs
 * - The carry is the AND of the inputs
 */
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

/*
 * Addition_Core
 *
 * Purpose:
 * - Performs addition on two 1-bit inputs and the carry bits
 *
 * Note:
 * - Is an expansion on the half adder where it includes the arithmetic for carry-over bits
 * - Meant to be used in a loop for n-bit addition
 * - Typically, this module would start with a carry-in bit of 0 for the first bit
 *   and would be updated over the course of the addition operation until a final carry-out
 *   bit is determined
 */
module Addition_Core #( parameter WIDTH = 4 ) (
    input wire in1,
    input wire in2,
    input wire carry_in,
    output wire out,
    output wire carry_out
);
    // Internal wires
    wire temp_out, temp_carry_out, carry_overflow;

    // Add the inputs and store the output
    Half_Adder input_adder_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( temp_out ),
        .carry_out( temp_carry_out )
    );

    // Add the carry
    Half_Adder carry_adder_instance (
        .in1( temp_out ),
        .in2( carry_in ),
        .out( out ),
        .carry_out( carry_overflow )
    );

    // Determine the final carry
    OR or_instance (
        .in1( temp_carry_out ),
        .in2( carry_overflow ),
        .out( carry_out )
    );
endmodule

/*
 * Half_Subtractor
 * Purpose:
 * - Performs subtraction on two 1-bit inputs and provides their difference and borrow
 *
 * Note:
 * - The difference is the XOR of the inputs
 * - The borrow is the AND of the inverted minuend and the subtrahend
 */
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

/*
 * Subtraction_Core
 * Purpose:
 * - Performs subtraction on two 1-bit inputs and the borrow bits
 *
 * Note:
 * - Is an expansion on the half subtractor where it includes the arithmetic for borrow-over bits
 * - Meant to be used in a loop for n-bit subtraction
 * - Typically, this module would start with a borrow-in bit of 0 for the first bit
 *   and would be updated over the course of the subtraction operation until a final borrow-out
 *   bit is determined
 */
module Subtraction_Core #( parameter WIDTH = 4 ) (
    input wire in1,
    input wire in2,
    input wire borrow_in,
    output wire out,
    output wire borrow_out
);
    // Internal wires
    wire temp_out, temp_borrow_out, borrow_overflow;

    // Subtract the inputs and store the output
    Half_Subtractor input_subtractor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( temp_out ),
        .borrow_out( temp_borrow_out )
    );

    // Subtract the borrow
    Half_Subtractor borrow_subtractor_instance (
        .in1( temp_out ),
        .in2( borrow_in ),
        .out( out ),
        .borrow_out( borrow_overflow )
    );

    // Determine the final borrow
    OR or_instance (
        .in1( temp_borrow_out ),
        .in2( borrow_overflow ),
        .out( borrow_out )
    );
endmodule

/*
 * Less_Than
 *
 * Purpose:
 * - Determines if the first n-bit input is less than the second n-bit input
 *
 * Note:
 * - The module uses the Full_Subtractor module to perform the comparison
 * - The final borrow bit is assigned as the output
 */
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

/*
 * Greater_Than
 *
 * Purpose:
 * - Determines if the first n-bit input is greater than the second n-bit input
 *
 * Note:
 * - The module uses the Less_Than module to perform the comparison
 * - The output is the inverse of the Less_Than output
 */
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

/*
 * Equal_To
 *
 * Purpose:
 * - Determines if the first n-bit input is equal to the second n-bit input
 *
 * Note:
 * - The module uses the Less_Than and Greater_Than modules to perform the comparison
 * - The output is the NOR of the Less_Than and Greater_Than results
 */
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
    Equal_To #( .WIDTH( 1'b1 ) ) equal_instance (
        .in1( in2[ step_counter ] ),
        .in2( 1'b1 ),
        .out( is_equal )
    );
endmodule

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