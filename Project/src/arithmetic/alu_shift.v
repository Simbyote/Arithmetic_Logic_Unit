/*
 * alu_shift.v
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
 * Parameters:
 * - WIDTH: The bit width of the input-output
 *
 * Implementation:
 * - The `UnpackPack_Shift` module provides a generalized framework to unpack
 *   packed inputs, perform the desired shift operation, and repack the outputs
 * - The `mXnBits_Shift` module performs a shift operation on a packed input of mxn bits
 * - The `nBit_Shift` module performs an arithmetic shift operation on an n-bit input
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