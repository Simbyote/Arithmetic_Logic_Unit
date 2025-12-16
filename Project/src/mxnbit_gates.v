`default_nettype none
/*
 * mxnbit_gates.v
 * This file contains a collection of scalable mxn-bit arithmetic
 * and logical modules, designed for bitwise operations on multiple sets
 * of n-bit inputs
 *
 * Purpose:
 * - These modules enable processing of multiple sets of logic operations 
 *   on n-bit input vectors
 *
 * Modules Included:
 * - UnpackPack_mXnbits: Core module that unpacks packed inputs, applies a specified
 *      logical or arithmetic operation, and repacks the results into a single output.
 * - NOT_mXnBits: Inverts each bit in multiple sets of n-bit inputs.
 * - AND_mXnBits: Computes the bitwise AND operation across corresponding bits in 
 *      multiple sets of n-bit inputs
 * - OR_mXnBits: Computes the bitwise OR operation across corresponding bits in 
 *      multiple sets of n-bit inputs
 * - NAND_mXnBits: Computes the bitwise NAND operation across corresponding bits in 
 *     multiple sets of n-bit inputs
 * - NOR_mXnBits: Computes the bitwise NOR operation across corresponding bits in 
 *     multiple sets of n-bit inputs
 * - XOR_mXnBits: Computes the bitwise XOR operation across corresponding bits in 
 *     multiple sets of n-bit inputs
 * - XNOR_mXnBits: Computes the bitwise XNOR operation across corresponding bits in 
 *      multiple sets of n-bit inputs
 *
 * Parameters:
 * - WIDTH: The bit width of the input-output
 * - OP: The logical operation to perform 
 * - SETS: The number of sets of n-bit inputs to process
 *
 * Implementation:
 * - The `UnpackPack_mXnbits` module provides a generalized framework to unpack
 *   packed input sets, perform the desired operation, and repack the outputs
 * - Each operation-specific module acts as a wrapper for the `UnpackPack_mXnbits` 
 *   module, passing the required parameters
 */

/*
 * UnpackPack_mXnbits
 *
 * Purpose:
 * - Takes a set of packed inputs and unpacks them into individual n-bit sets,
 *   that are then processed based on the specified operation. The results are
 *   repacked into a single output
 */
module mXnBit_UnpackPack #( parameter WIDTH = 4, parameter SETS = 2, parameter OP = 0 ) (
    input wire [ SETS*WIDTH-1:0 ] in1_packed,
    input wire [ SETS*WIDTH-1:0 ] in2_packed,
    output wire [ SETS*WIDTH-1:0 ] out_packed
);
    // Compile-time check for the operations
    generate
        if( OP < 0 || OP > 6 ) begin
            initial begin
                $error( "Error: Invalid OP value (%0d). Must be between 0 and 6", OP );
            end
        end
    endgenerate

    // Internal wires for unpacked inputs and outputs
    wire [ WIDTH-1:0 ] in1_unpacked[ SETS-1:0 ];
    wire [ WIDTH-1:0 ] in2_unpacked[ SETS-1:0 ];
    wire [ WIDTH-1:0 ] out_unpacked[ SETS-1:0 ];

    genvar i;
    generate
        // Unpack the packed inputs into individual sets
        for( i = 0; i < SETS; i = i + 1 ) begin : unpack_inputs
            assign in1_unpacked[ i ] = in1_packed[ i*WIDTH +: WIDTH ];
            assign in2_unpacked[ i ] = in2_packed[ i*WIDTH +: WIDTH ];
        end

        // Apply the corresponding operation to each set
        for( i = 0; i < SETS; i = i + 1 ) begin : instantiate
            if( OP == 0 )
                nBit_NOT #( .WIDTH( WIDTH ) ) not_instance (
                    .in( in1_unpacked[ i ] ),
                    .out( out_unpacked[ i ] )
                );
            else if( OP == 1 )
                nBit_AND #( .WIDTH( WIDTH ) ) and_instance (
                    .in1( in1_unpacked[ i ] ),
                    .in2( in2_unpacked[ i ] ),
                    .out( out_unpacked[ i ] )
                );
            else if( OP == 2 )
                nBit_OR #( .WIDTH( WIDTH ) ) or_instance (
                    .in1( in1_unpacked[ i ] ),
                    .in2( in2_unpacked[ i ] ),
                    .out( out_unpacked[ i ] )
                );
            else if( OP == 3 )
                nBit_NAND #( .WIDTH( WIDTH ) ) nand_instance (
                    .in1( in1_unpacked[ i ] ),
                    .in2( in2_unpacked[ i ] ),
                    .out( out_unpacked[ i ] )
                );
            else if( OP == 4 )
                nBit_NOR #( .WIDTH( WIDTH ) ) nor_instance (
                    .in1( in1_unpacked[ i ] ),
                    .in2( in2_unpacked[ i ] ),
                    .out( out_unpacked[ i ] )
                );
            else if( OP == 5 )
                nBit_XOR #( .WIDTH( WIDTH ) ) xor_instance (
                    .in1( in1_unpacked[ i ] ),
                    .in2( in2_unpacked[ i ] ),
                    .out( out_unpacked[ i ] )
                );
            else if( OP == 6 )
                nBit_XNOR #( .WIDTH( WIDTH ) ) xnor_instance (
                    .in1( in1_unpacked[ i ] ),
                    .in2( in2_unpacked[ i ] ),
                    .out( out_unpacked[ i ] )
                );
        end

        // Pack the individual sets into a single output
        for( i = 0; i < SETS; i = i + 1 ) begin : pack_outputs
            assign out_packed[ i*WIDTH +: WIDTH ] = out_unpacked[ i ];
        end
    endgenerate
endmodule

/*
 * mXnBits_NOT
 * 
 * Purpose:
 * - Wraps with the mXnBits_UnpackPack module to perform the NOT operation
 *   on multiple sets of n-bit inputs
 */
module mXnBit_NOT #( parameter WIDTH = 4, parameter SETS = 2 ) (
    input wire [ SETS*WIDTH-1:0 ] in_packed,
    output wire [ SETS*WIDTH-1:0 ] out_packed
);  

    // Unpack, instantiate NOT operation (0), and pack the output
    mXnBit_UnpackPack #( .WIDTH( WIDTH ), .SETS( SETS ), .OP ( 0 ) ) not_unpack_pack (
        .in1_packed( in_packed ),
        .out_packed( out_packed )
    );
endmodule

/*
 * mXnBits_AND
 *
 * Purpose:
 * - Wraps with the mXnBits_UnpackPack module to perform the AND operation
 *   on multiple sets of n-bit inputs
 */
module mXnBit_AND #( parameter WIDTH = 4, parameter SETS = 2 ) (
    input wire [ SETS*WIDTH-1:0 ] in1_packed,
    input wire [ SETS*WIDTH-1:0 ] in2_packed,
    output wire [ SETS*WIDTH-1:0 ] out_packed
);  

    // Unpack, instantiate AND operation (1), and pack the output
    mXnBit_UnpackPack #( .WIDTH( WIDTH ), .SETS( SETS ), .OP ( 1 ) ) and_pack_unpack (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( out_packed )
    );
endmodule

/*
 * mXnBits_OR
 *
 * Purpose:
 * - Wraps with the mXnBits_UnpackPack module to perform the OR operation
 *   on multiple sets of n-bit inputs
 */
module mXnBit_OR #( parameter WIDTH = 4, parameter SETS = 2 ) (
    input wire [ SETS*WIDTH-1:0 ] in1_packed,
    input wire [ SETS*WIDTH-1:0 ] in2_packed,
    output wire [ SETS*WIDTH-1:0 ] out_packed
);  

    // Unpack, instantiate OR operation (2), and pack the output
    mXnBit_UnpackPack #( .WIDTH( WIDTH ), .SETS( SETS ), .OP ( 2 ) ) or_pack_unpack (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( out_packed )
    );
endmodule

/*
 * mXnBits_NAND
 *
 * Purpose:
 * - Wraps with the mXnBits_UnpackPack module to perform the NAND operation
 *   on multiple sets of n-bit inputs
 */
module mXnBit_NAND #( parameter WIDTH = 4, parameter SETS = 2 ) (
    input wire [ SETS*WIDTH-1:0 ] in1_packed,
    input wire [ SETS*WIDTH-1:0 ] in2_packed,
    output wire [ SETS*WIDTH-1:0 ] out_packed
);  

    // Unpack, instantiate NAND operation (3), and pack the output
    mXnBit_UnpackPack #( .WIDTH( WIDTH ), .SETS( SETS ), .OP ( 3 ) ) nand_pack_unpack (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( out_packed )
    );
endmodule

/*
 * mXnBits_NOR
 *
 * Purpose:
 * - Wraps with the mXnBits_UnpackPack module to perform the NOR operation
 *   on multiple sets of n-bit inputs
 */
module mXnBit_NOR #( parameter WIDTH = 4, parameter SETS = 2 ) (
    input wire [ SETS*WIDTH-1:0 ] in1_packed,
    input wire [ SETS*WIDTH-1:0 ] in2_packed,
    output wire [ SETS*WIDTH-1:0 ] out_packed
);  

    // Unpack, instantiate NOR operation (4), and pack the output
    mXnBit_UnpackPack #( .WIDTH( WIDTH ), .SETS( SETS ), .OP ( 4 ) ) nor_pack_unpack (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( out_packed )
    );
endmodule    

/*
 * mXnBits_XOR
 * 
 * Purpose:
 * - Wraps with the mXnBits_UnpackPack module to perform the XOR operation
 *   on multiple sets of n-bit inputs
 */
module mXnBit_XOR #( parameter WIDTH = 4, parameter SETS = 2 ) (
    input wire [ SETS*WIDTH-1:0 ] in1_packed,
    input wire [ SETS*WIDTH-1:0 ] in2_packed,
    output wire [ SETS*WIDTH-1:0 ] out_packed
);  

    // Unpack, instantiate XOR operation (5), and pack the output
    mXnBit_UnpackPack #( .WIDTH( WIDTH ), .SETS( SETS ), .OP ( 5 ) ) xor_pack_unpack (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( out_packed )
    );
endmodule

/*
 * mXnBits_XNOR
 *
 * Purpose:
 * - Wraps with the mXnBits_UnpackPack module to perform the XNOR operation
 *   on multiple sets of n-bit inputs
 */
module mXnBit_XNOR #( parameter WIDTH = 4, parameter SETS = 2 ) (
    input wire [ SETS*WIDTH-1:0 ] in1_packed,
    input wire [ SETS*WIDTH-1:0 ] in2_packed,
    output wire [ SETS*WIDTH-1:0 ] out_packed
);  

    // Unpack, instantiate XNOR operation (6), and pack the output
    mXnBit_UnpackPack #( .WIDTH( WIDTH ), .SETS( SETS ), .OP ( 6 ) ) xnor_pack_unpack (
        .in1_packed( in1_packed ),
        .in2_packed( in2_packed ),
        .out_packed( out_packed )
    );
endmodule

    