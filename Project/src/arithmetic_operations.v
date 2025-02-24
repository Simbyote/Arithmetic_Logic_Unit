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
module New_UnpackPack_Shift #( parameter WIDTH = 4, parameter SETS = 2, parameter OP = 0 ) (
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
            New_nBit_Shift #( .WIDTH( WIDTH ), .OP( OP ) ) shift(
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
module New_nBit_Shift #( parameter WIDTH = 4, parameter OP = 0 ) (
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
module New_mXnBits_Shift #( parameter WIDTH = 4, parameter SETS = 2, parameter OP = 0) (
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
            New_UnpackPack_Shift #( .WIDTH( WIDTH ), .SETS( SETS ), .OP( 0 ) ) shift_logical(
                .in_packed( in_packed ),
                .shift_packed( shift_packed ),
                .out_packed( out_packed ),
                .overflow_packed( overflow_packed )
            ); 
        end
        else if( OP == 1 ) begin
            // Unpack, shift arithmetically, and pack the inputs and outputs
            New_UnpackPack_Shift #( .WIDTH( WIDTH ), .SETS( SETS ), .OP( 1 ) ) shift_arithmetic(
                .in_packed( in_packed ),
                .shift_packed( shift_packed ),
                .out_packed( out_packed ),
                .overflow_packed( overflow_packed )
            );
        end
    endgenerate
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
        for( i = 0; i < WIDTH; i = i + 1 ) begin : adder_loop
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
    wire [ WIDTH-1:0 ] borrow_in, borrow_out;
    assign borrow_in[ 0 ] = 1'b0;

    genvar i;
    generate
        for( i = 0; i < WIDTH; i = i + 1 ) begin : subtractor_loop
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
                .out( out[ i ] ),
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
        end
    endgenerate
endmodule

module New_Multiplier #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output reg [ ( WIDTH*2 )-1:0 ] out
);
    parameter PRODUCT_WIDTH = ( WIDTH*2 );  // The width of the product

    // Internal wires
    wire [ PRODUCT_WIDTH*WIDTH-1:0 ] accumulator;
    reg [ PRODUCT_WIDTH-1:0 ] partial_sum[ WIDTH-1:0 ];

    // Generate the accumulator
    Generate_Accumulator #( .WIDTH( WIDTH ) ) accumulator_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( accumulator )
    );

    reg [ WIDTH-1:0 ] i;    // Loop counters

    always @(*) begin
        // Default output
        out = { WIDTH{ 1'b0 } };

        for( i = 0; i < WIDTH; i = i + 1 ) begin : multiplier_loop
            if( i == 0 ) begin
                if( in2[ i ] == 1 ) begin
                    // Assign the first output to the first accumulator value
                    partial_sum[ i ] = accumulator[ i * PRODUCT_WIDTH +: PRODUCT_WIDTH ];
                end
                else begin
                    // Assign the first output to 0
                    partial_sum[ i ] = { WIDTH{ 1'b0 } };
                end
            end
            else begin
                if( in2[ i ] == 1'b1 ) begin
                // Compute partial sum
                partial_sum[ i ] = partial_sum[ i -1 ] + accumulator[ i * PRODUCT_WIDTH +: PRODUCT_WIDTH ];
                end
                else begin
                    // Carry over the previous sum
                    partial_sum[ i ] = partial_sum[ i - 1 ];
                end
            end
        end

        out = partial_sum[ WIDTH - 1 ];
    end
endmodule

module Generate_Accumulator #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ ( PRODUCT_WIDTH*WIDTH )-1:0 ] out
);
    parameter PRODUCT_WIDTH = ( WIDTH*2 );  // The width of the product

    genvar i;
    generate
        for( i = 0; i < WIDTH; i = i + 1 ) begin : accumulator_loop
            // Internal wires of the shift operation
            wire [ WIDTH-1:0 ] shift, overflow, shift_result;
            wire [ PRODUCT_WIDTH-1:0 ] temp_out;    
            wire [ WIDTH-2:0 ] shift_amt;
            wire final_carry;

            // Assign the shift amount
            assign shift_amt = i;
            assign shift = { 1'b0, shift_amt, 1'b0 };

            New_nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shift_instance (
                .in( in1 ),
                .shift( shift ),
                .out( shift_result ),
                .overflow( overflow )
            );

            // Assign the shifted output to the final output
            assign temp_out = { overflow, shift_result };
            assign out[ i*PRODUCT_WIDTH +: PRODUCT_WIDTH ] = temp_out;      
        end
    endgenerate
endmodule

module Multiplier #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ ( WIDTH*2 )-1:0 ] out
);
    parameter PRODUCT_WIDTH = ( WIDTH*2 );  // The width of the product
    // Internal wires
    wire [ PRODUCT_WIDTH*WIDTH-1:0 ] accumulator;
    wire [ PRODUCT_WIDTH-1:0 ] partial_sum[ WIDTH-1:0 ];
    wire [ PRODUCT_WIDTH-1:0 ] shifted_in[ WIDTH-1:0 ];

    Generate_Accumulator #( .WIDTH( WIDTH ) ) accumulator_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( accumulator )
    );

    assign partial_sum[ 0 ] = in2[ 0 ] ? accumulator[ 0*PRODUCT_WIDTH +: PRODUCT_WIDTH ] : { WIDTH{ 1'b0 } };

    // Parse the accumulator and add the results
    genvar i;
    generate
        for( i = 1; i < WIDTH; i = i + 1 ) begin : multiplier_loop
            wire [ PRODUCT_WIDTH-1:0 ] temp_out;
            wire final_carry;

            // Add the current output to the previous output
            Full_Adder #( .WIDTH( PRODUCT_WIDTH ) ) adder_instance (
                .in1( accumulator[ i*PRODUCT_WIDTH +: PRODUCT_WIDTH ] ),
                .in2( partial_sum[ i - 1 ] ),
                .out( temp_out ),
                .final_carry( final_carry )
            );

            // Assign the current output to the final carry and its output
            assign partial_sum[ i ] = in2[ i ] ? { final_carry, temp_out } : partial_sum[ i - 1 ];
        end

        // Assign the final output to the last output
        assign out = partial_sum[ WIDTH - 1 ];
    endgenerate
endmodule