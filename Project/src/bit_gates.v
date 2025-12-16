`default_nettype none
/*
 * bit_gates.v
 * This file contains the fundamental and derived logic gates
 * that form the building blocks for more complex operations.
 *
 * Purpose:
 * - These gates are used as essential components in higher-level designs
 *
 * Modules Included:
 * - NOT Gate: Inverts a single input signal
 * - AND Gate: Produces a high output (1) only when all inputs are high
 * - OR Gate: Produces a high output (1) if any input is high
 * - NAND Gate: Produces a low output (0) only when all inputs are high
 * - NOR Gate: Produces a low output (0) if any input is high
 * - XOR Gate: Produces a high output (1) when inputs are different
 * - XNOR Gate: Produces a low output (0) when inputs are different
 */

/* NOT Gate
 * Purpose:
 * - Takes one input signal and inverts it to produce the output
 *   signal
 * 
 * Note: 
 * - The `~` operator is used to invert the input signal
 */
module NOT (
    input wire in,
    output wire out
);
    assign out = ~in;
endmodule

/* AND Gate
 * Purpose:
 * - Takes two input signals and produces a high output (1) only
 *   when both inputs are high
 *
 * Note: 
 * - The `&` operator is used to perform the AND operation
 */
module AND (
    input wire in1,
    input wire in2,
    output wire out  
);
    assign out = in1 & in2;
endmodule

/* OR Gate
 * Purpose:
 * - Takes two input signals and produces a high output (1) if
 *   either input is high
 *
 * Note: 
 * - The `|` operator is used to perform the OR operation
 */
module OR (
    input wire in1,
    input wire in2,
    output wire out
);
    assign out = in1 | in2;
endmodule

/* NAND Gate
 * Purpose:
 * - Takes two input signals and produces a low output (0) only
 *   when both inputs are high
 * - Is the inverse of the AND gate
 *
 * Note:
 * We instantiate the AND module to implement the NAND gate
 * combining the operators `~` and `&`
 */
module NAND (
    input wire in1,
    input wire in2,
    output wire out
);
    wire and_result;
    AND and_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( and_result )
    );
    assign out = ~and_result;
endmodule

/* NOR Gate
 * Purpose:
 * - Takes two input signals and produces a low output (0) if
 *   either input is high
 * - Is the inverse of the OR gate
 *
 * - We instantiate the OR module to implement the NOR gate
 *   combining the operators `~` and `|`
 */
module NOR (
    input wire in1,
    input wire in2,
    output wire out
);
    wire or_result;
    OR or_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( or_result )
    );
    assign out = ~or_result;
endmodule

/* XOR Gate
 * Purpose:
 * - Takes two input signals and produces a high output (1) when
 *   inputs are different
 *
 * Note: 
 * - The '^' operator is used to perform the XOR operation
 */
module XOR (
    input wire in1,
    input wire in2,
    output wire out
);
    assign out = in1 ^ in2;
endmodule

/* XNOR Gate
 * Purpose:
 * - Takes two input signals and produces a low output (0) when
 *   inputs are different
 * - Is the inverse of the XOR gate
 *
 * - We instantiate the XOR module to implement the XNOR gate
 *   combining the operators '~' and '^'
 */
module XNOR (
    input wire in1,
    input wire in2,
    output wire out
);
    wire xor_result;
    XOR xor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( xor_result )
    );
    assign out = ~xor_result;
endmodule