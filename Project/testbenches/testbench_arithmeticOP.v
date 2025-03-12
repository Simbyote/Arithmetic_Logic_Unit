`timescale 1ns/1ns
module testbench_arithmeticOP;
    parameter WIDTH = 4;    // The number of bits for the input-output
    parameter BIT_STATE = 2 ** WIDTH;   // The total possible states for the given bit WIDTH

    // Less Than Comparator
    reg [ WIDTH-1:0 ] less_in1, less_in2;
    wire less_out;

    Less_Than #( .WIDTH( WIDTH ) ) less_than_instance (
        .in1( less_in1 ),
        .in2( less_in2 ),
        .out( less_out )
    );

    // Greater Than Comparator
    reg [ WIDTH-1:0 ] greater_in1, greater_in2;
    wire greater_out;

    Greater_Than #( .WIDTH( WIDTH ) ) greater_than_instance (
        .in1( greater_in1 ),
        .in2( greater_in2 ),
        .out( greater_out )
    );

    // Equal To Comparator
    reg [ WIDTH-1:0 ] equal_in1, equal_in2;
    wire equal_out;

    Equal_To #( .WIDTH( WIDTH ) ) equal_instance (
        .in1( equal_in1 ),
        .in2( equal_in2 ),
        .out( equal_out )
    );

    // Half Adder
    reg half_in1, half_in2;
    wire half_adder_out, half_adder_carry_out;

    Half_Adder #( .WIDTH( WIDTH ) ) adder_instance (
        .in1( half_in1 ),
        .in2( half_in2 ),
        .out( half_adder_out ),
        .carry_out( half_adder_carry_out )
    );

    // Half Subtractor
    wire half_subtractor_out, half_subtractor_borrow_out;

    Half_Subtractor #( .WIDTH( WIDTH ) ) subtractor_instance (
        .in1( half_in1 ),
        .in2( half_in2 ),
        .out( half_subtractor_out ),
        .borrow_out( half_subtractor_borrow_out )
    );

    // Full Adder
    reg [ WIDTH-1:0 ] full_in1, full_in2;
    wire [ WIDTH-1:0 ] full_adder_out;
    wire final_carry;

    Full_Adder #( .WIDTH( WIDTH ) ) full_adder_instance (
        .in1( full_in1 ),
        .in2( full_in2 ),
        .out( full_adder_out ),
        .final_carry( final_carry )
    );    

    // Full Subtractor
    wire [ WIDTH-1:0 ] full_subtractor_out;
    wire final_borrow;

    Full_Subtractor #( .WIDTH( WIDTH ) ) full_subtractor_instance (
        .in1( full_in1 ),
        .in2( full_in2 ),
        .out( full_subtractor_out ),
        .final_borrow( final_borrow )
    );

    // Multiplier
    reg [ WIDTH-1:0 ] mult_in1, mult_in2;
    wire [ WIDTH-1:0 ] mult_low, mult_high;

    Multiplier #( .WIDTH( WIDTH ) ) multiplier_instance (
        .in1( mult_in1 ),
        .in2( mult_in2 ),
        .out_low( mult_low ),
        .out_high( mult_high )
    );

    // Divider
    reg [ WIDTH-1:0 ] div_in1, div_in2;
    wire [ WIDTH-1:0 ] div_out, div_remainder;

    Divider #( .WIDTH( WIDTH ) ) divider_instance (
        .in1( div_in1 ),
        .in2( div_in2 ),
        .out( div_out ),
        .remainder( div_remainder )
    );

    `define GENERIC_HALF( REG1, REG2 ) \
        begin \
            REG1 = { 1'b0 }; \
            repeat( 2 ) begin \
                REG2 = { 1'b0 }; \
                repeat( 2 ) begin \
                    #10; \
                    REG2 = REG2 + 1; \
                end \
                REG1 = REG1 + 1; \
            end \
        end

    `define GENERIC_FULL( REG1, REG2 ) \
        begin \
            REG1 = { WIDTH{ 1'b0 } }; \
            repeat( BIT_STATE ) begin \
                REG2 = { WIDTH{ 1'b0 } }; \
                repeat( BIT_STATE ) begin \
                    #10; \
                    REG2 = REG2 + 1; \
                end \
                REG1 = REG1 + 1; \
            end \
            REG1 = { WIDTH{ 1'b0 } }; \
            REG2 = { WIDTH{ 1'b0 } }; \
        end

    initial begin
        $dumpfile( "waveform6.vcd" );
        $dumpvars( 0, testbench_arithmeticOP );

        `GENERIC_FULL( div_in1, div_in2 );
        
        #50 $finish;
    end
endmodule