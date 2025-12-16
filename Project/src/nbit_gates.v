`default_nettype none
/*
 * nbit_gates.v
 * This file contains a collection of n-bit logic gates that operate on
 * n-bit input vectors.
 *
 * Purpose:
 * These modules enables one to process a single set of logic operations 
 * on n-bit input vectors
 *
 * Modules Included:
 * - Gate_Instantiator: Core module that instantiates the required gate based on the
 *      specified operation
 * - NOT_nBit: Inverts each bit in an n-bit input
 * - AND_nBit: Checks if both corresponding bits are high in two n-bit inputs
 * - OR_nBit: Checks if either corresponding bit is high in two n-bit inputs
 * - NAND_nBit: Inverts the result of the AND operation
 * - NOR_nBit: Inverts the result of the OR operation
 * - XOR_nBit: Detects differences in each bit between two n-bit inputs
 * - XNOR_nBit: Detects similarities in each bit  between two n-bit inputs
 *
 * Parameters:
 * - WIDTH: The bit width of the input-output
 * - OP: The logical operation to perform 
 *
 * Implementation:
 * - The `Gate_Instantiator` module provides a generalized framework to instantiate
 *   the required gate based on the specified operation
 * - Each operation-specific module acts as a wrapper for the `Gate_Instantiator` 
 *   module, passing the required parameters
 */

/*
 * Gate_Instantiator
 *
 * Purpose:
 * - Dynamically instantiates the required gate based on the OP parameter
 *
 * Implementation:
 * - A `generate` block is used to instantiate the appropriate gate for each bit 
 *   in the input vectors
 * - An `initial` block ensures compile-time validation of the OP parameter, 
 *   throwing an error if it is invalid
 */

module Gate_Instantiator #( parameter WIDTH = 4 , parameter OP = 0 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out
);
    // Compile-time check for the operations
    generate
        if( OP < 0 || OP > 6 ) begin
            initial begin
                $error( "Error: Invalid OP value (%0d). Must be between 0 and 6", OP );
            end
        end
    endgenerate

    // Instantiate the required gate based on the OP value
    genvar i;
    generate
        for( i = 0; i < WIDTH; i = i + 1 ) begin : gate_loop
            case( OP )
                0: begin
                    NOT not_instance (
                        .in( in1[ i ] ),
                        .out( out[ i ] )
                    );
                end
                1: begin
                    AND and_instance (
                        .in1( in1[ i ] ),
                        .in2( in2[ i ] ),
                        .out( out[ i ] )
                    );
                end
                2: begin
                    OR or_instance (
                        .in1( in1[ i ] ),
                        .in2( in2[ i ] ),
                        .out( out[ i ] )
                    );
                end
                3: begin
                    NAND nand_instance (
                        .in1( in1[ i ] ),
                        .in2( in2[ i ] ),
                        .out( out[ i ] )
                    );
                end
                4: begin
                    NOR nor_instance (
                        .in1( in1[ i ] ),
                        .in2( in2[ i ] ),
                        .out( out[ i ] )
                    );
                end
                5: begin
                    XOR xor_instance (
                        .in1( in1[ i ] ),
                        .in2( in2[ i ] ),
                        .out( out[ i ] )
                    );
                end
                6: begin
                    XNOR xnor_instance (
                        .in1( in1[ i ] ),
                        .in2( in2[ i ] ),
                        .out( out[ i ] )
                    );
                end
                default: begin
                    initial begin
                        $error( "Error: Invalid OP value (%0d). Must be between 0 and 6", OP );
                    end
                end
            endcase
        end
    endgenerate
endmodule

/*
 * NOT_nBit
 *
 * Purpose:
 * - Processes each bit in a n-bit input and computes the bitwise NOT
 *   inverting each bit
 */
module nBit_NOT #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in,
    output wire [ WIDTH-1:0 ] out
);

    // Instantiate the corresonding operation (NOT - 0)
    Gate_Instantiator #(.WIDTH( WIDTH ), .OP( 0 ) ) not_instance (
        .in1( in ),
        .in2( in ),
        .out( out )
    );
endmodule

/*
 * AND_nBit
 *
 * Purpose:
 * - Processes each bit in two n-bit inputs and computes the bitwise AND
 *   operation on each pair of bits
 */
module nBit_AND #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out
);

    // Instatiate the corresponding operation (AND - 1)
    Gate_Instantiator #(.WIDTH( WIDTH ), .OP( 1 ) ) and_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( out )
    );
endmodule

/*
 * OR_nBit
 *
 * Purpose:
 * - Processes each bit in two n-bit inputs and computes the bitwise OR
 *   operation on each pair of bits
 */
module nBit_OR #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out
);

    // Instantiate the corresponding operation (OR - 2)
    Gate_Instantiator #(.WIDTH( WIDTH ), .OP( 2 ) ) or_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( out )
    );
endmodule

/*
 * NAND_nBit
 *
 * Purpose:
 * - Processes each bit in two n-bit inputs and computes the bitwise NAND
 *   operation on each pair of bits
 */
module nBit_NAND #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out
);

    // Instantiate the corresponding operation (NAND - 3)
    Gate_Instantiator #(.WIDTH( WIDTH ), .OP( 3 ) ) nand_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( out )
    );
endmodule

/*
 * NOR_nBit
 *
 * Purpose:
 * - Processes each bit in two n-bit inputs and computes the bitwise NOR
 *   operation on each pair of bits
 */
module nBit_NOR #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out
);

    // Instantiate the corresponding operation (NOR - 4)
    Gate_Instantiator #(.WIDTH( WIDTH ), .OP( 4 ) ) nor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( out )
    );
endmodule

/*
 * XOR_nBit
 *
 * Purpose:
 * - Processes each bit in two n-bit inputs and computes the bitwise XOR
 *   operation on each pair of bits
 */
module nBit_XOR #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out
);

    // Instantiate the corresponding operation (XOR - 5)
    Gate_Instantiator #(.WIDTH( WIDTH ), .OP( 5 ) ) xor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( out )
    );
endmodule

/*
 * XNOR_nBit
 *
 * Purpose:
 * - Processes each bit in two n-bit inputs and computes the bitwise XNOR
 *   operation on each pair of bits
 */
module nBit_XNOR #( parameter WIDTH = 4 ) (
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output wire [ WIDTH-1:0 ] out
);

    // Instantiate the corresponding operation (XNOR - 6)
    Gate_Instantiator #(.WIDTH( WIDTH ), .OP( 6 ) ) xnor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( out )
    );
endmodule