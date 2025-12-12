/*
 * combinational_alu.v
 * Purpose:
 * - Contains the modules for the combinational ALU operations
 *
 * Modules Included:
 * Parameters:
 * - WIDTH: The bit-width of the input and output signals
 *
 * Implementation:
 */

 module FLAGS #( parameter WIDTH = 4 ) (
    input wire [WIDTH-1:0] A,
    input wire [WIDTH-1:0] B,
    input wire [WIDTH-1:0] out,
    input wire sel,
    output wire zero_flag,
    output wire negative_flag,
    output wire overflow_flag
 );
    // Internal wires
    wire in_ov, out_ov, n_in_ov;
    wire ov_add, ov_sub;

    wire msb_a = A[WIDTH-1];
    wire msb_b = B[WIDTH-1];
    wire msb_out = out[WIDTH-1];

    // in_ov = A_sign XOR B_sign
    // 0 = A and B have same sign (needed for ADD overflow)
    // 1 = A and B have opposite signs (needed for SUB overflow)    
    XOR input_overflow (
        .in1( msb_a ),
        .in2( msb_b ),
        .out( in_ov )
    );

    // out_ov = A_sign XOR OUT_sign
    // 1 = result sign differs from A's sign (part of the overflow condition)
    XOR output_overflow (
        .in1( msb_a ),
        .in2( msb_out ),
        .out( out_ov )
    );

    // Invert the input overflow signal
    NOT overflow_not (
        .in( in_ov ),
        .out( n_in_ov )
    );

    // If A and B have the same sign and out has a different sign, overflow has occurred for addition
    AND overflow_add (
        .in1( n_in_ov ),
        .in2( out_ov ),
        .out( ov_add )
    );

    // If A and B have different signs and out has a different sign than A, overflow has occurred for subtraction
    AND overflow_sub (
        .in1( in_ov ),
        .in2( out_ov ),
        .out( ov_sub )
    );

    // Assign the flags
    assign zero_flag = (out == {WIDTH{1'b0}}) ? 1'b1 : 1'b0;
    assign negative_flag = msb_out;
    assign overflow_flag = (sel == 1'b0) ? ov_add : ov_sub;
 endmodule

 module ADD_SUB #( parameter WIDTH = 4 ) (
    input wire [WIDTH-1:0] A,
    input wire [WIDTH-1:0] B,
    input wire sel, 
    output wire [WIDTH-1:0] out,
    output wire carry_or_borrow_out,
    output wire zero_flag,
    output wire negative_flag,
    output wire overflow_flag
 );
    // Internal wires
    wire [WIDTH-1:0] sum, diff;    
    wire carry, borrow;

    // Perform the addition
    Full_Adder #( .WIDTH( WIDTH ) ) adder_instance (
        .in1( A ),
        .in2( B ),
        .out( sum ),
        .final_carry( carry )
    );

    // Perform the subtraction
    Full_Subtractor #( .WIDTH( WIDTH ) ) subtractor_instance (
        .in1( A ),
        .in2( B ),
        .out( diff ),
        .final_borrow( borrow )
    );

    // Mux to select between addition and subtraction based on sel
    assign out = (sel == 1'b0) ? sum : diff;
    assign carry_or_borrow_out = (sel == 1'b0) ? carry : borrow;

    // Assign the proper flags
    FLAGS #( .WIDTH( WIDTH ) ) flags_instance (
        .A( A ),
        .B( B ),
        .out( out ),
        .sel( sel ),
        .zero_flag( zero_flag ),
        .negative_flag( negative_flag ),
        .overflow_flag( overflow_flag )
    );
 endmodule
