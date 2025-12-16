`default_nettype none
/*
 * alu_addsub_compare.v
 * Contains modules for performing arithmetic operations on n-bit inputs
 *
 * Purpose:
 * - These modules perform arithmetic operations on n-bit inputs
 *
 * Modules Included:
 * - Half_Adder: Performs addition on two 1-bit inputs and provides their sum and carry
 * - Addition_Core: Performs addition on two 1-bit inputs and the carry bits
 * - Full_Adder: Upper layer datapath for the addition operation
 *
 * - Half_Subtractor: Performs subtraction on two 1-bit inputs and provides their difference and borrow
 * - Subtraction_Core: Performs subtraction on two 1-bit inputs and the borrow bits
 * - Full_Subtractor: Upper layer datapath for the subtraction operation
 *
 * - Less_Than: Determines if the first n-bit input is less than the second n-bit input
 * - Greater_Than: Determines if the first n-bit input is greater than the second n-bit input
 * - Equal_To: Determines if the first n-bit input is equal to the second n-bit input
 *
 * Parameters:
 * - WIDTH: The bit width of the input-output
 * - OP: The logical operation to perform 
 * - SETS: The number of sets of n-bit inputs to process
 *
 * Implementation:

 * - The `Half_Adder` module performs addition on two 1-bit inputs and provides their sum and carry
 * - The `Addition_Core` module performs addition on two 1-bit inputs and the carry bits
 * - The "Full_Adder" performs the addition over a generate loop to collect the sum and carry-out bits

 * - The `Half_Subtractor` module performs subtraction on two 1-bit inputs and provides their difference and borrow
 * - The `Subtraction_Core` module performs subtraction on two 1-bit inputs and the borrow bits
 * - The "Full_Subtractor" performs the subtraction over a generate loop to collect the difference and borrow-out bits

 * - The `Less_Than` module determines if the first n-bit input is less than the second n-bit input
 * - The `Greater_Than` module determines if the first n-bit input is greater than the second n-bit input
 * - The `Equal_To` module determines if the first n-bit input is equal to the second n-bit input
 */

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
module Addition_Core #( parameter WIDTH = 0 ) (
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
 * Full_Adder
 *
 * Purpose:
 * - Datapath of the addition operation utilizing the Addition_Core module
 *
 * Note:
 * - The addition operation is performed using a generate loop to iterate over the bits
 * - From the "Addition_Core" module, the sum of the current bits are stored in the output
 *   and the carry-out bit is moved to the next bit, unless it is the final bit, to which
 *   it is assigned to the final carry-out bit
 */
module Full_Adder #( parameter WIDTH = 0 ) (
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
    // Internal wires
    wire in1_not;

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
module Subtraction_Core #( parameter WIDTH = 0 ) (
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
 * Full_Subtractor
 * Purpose:
 * - Datapath of the subtraction operation utilizing the Subtraction_Core module
 *
 * Note:
 * - The subtraction operation is performed using a generate loop to iterate over the bits
 * - From the "Subtraction_Core" module, the difference of the current bits are stored in the output
 *   and the borrow-out bit is moved to the next bit, unless it is the final bit, to which
 *   it is assigned to the final borrow-out bit
 */
module Full_Subtractor #( parameter WIDTH = 0 ) (
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
 * Less_Than
 *
 * Purpose:
 * - Determines if the first n-bit input is less than the second n-bit input
 *
 * Note:
 * - The module uses the Full_Subtractor module to perform the comparison
 * - The final borrow bit is assigned as the output
 */
module Less_Than #( parameter WIDTH = 0 ) (
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
module Greater_Than #( parameter WIDTH = 0 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire out
);
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
module Equal_To #( parameter WIDTH = 0) (
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
    NOR nor_instance (
        .in1( less_than_result ),
        .in2( greater_than_result ),
        .out( out )
    );    
endmodule