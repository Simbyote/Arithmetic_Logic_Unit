`timescale 1ns/1ns
module testbench_arithmeticOP;
    parameter WIDTH = 4;    // The number of bits for the input-output
    parameter BIT_STATE = 2 ** WIDTH;   // The total possible states for the given bit WIDTH

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
    wire [ ( WIDTH*2 )-1:0 ] mult_out;

    New_Multiplier #( .WIDTH( WIDTH ) ) always_method (
        .in1( mult_in1 ),
        .in2( mult_in2 ),
        .out( mult_out )
    );

    Multiplier #( .WIDTH( WIDTH ) ) generate_method (
        .in1( mult_in1 ),
        .in2( mult_in2 ),
        .out( mult_out )
    );

    task test_half;
        begin
            half_in1 = { 1'b0 };
            repeat( 2 ) begin
                half_in2 = { 1'b0 };
                repeat( 2 ) begin
                    #10;
                    half_in2 = half_in2 + 1;
                end
                half_in1 = half_in1 + 1;
            end
        end
    endtask

    task test_full;
        begin
            full_in1 = { WIDTH{ 1'b0 } }; 

            repeat( BIT_STATE ) begin
                full_in2 = { WIDTH{ 1'b0 } };
                repeat( BIT_STATE ) begin
                    #10;
                    full_in2 = full_in2 + 1;
                end
                full_in1 = full_in1 + 1;
            end
            full_in1 = { WIDTH{ 1'b0 } } ;
            full_in2 = { WIDTH{ 1'b0 } };
        end
    endtask 

    task test_multiplier;
        begin
            mult_in1 = { WIDTH{ 1'b0 } };

            repeat( BIT_STATE ) begin
                mult_in2 = { WIDTH{ 1'b0 } };

                repeat( BIT_STATE ) begin
                    #10;
                    mult_in2 = mult_in2 + 1;

                end

                mult_in1 = mult_in1 + 1;
            end
            mult_in1 = { WIDTH{ 1'b0 } };
            mult_in2 = { WIDTH{ 1'b0 } };
        end
    endtask

    initial begin
        $dumpfile( "waveform6.vcd" );
        $dumpvars( 0, testbench_arithmeticOP );


        test_multiplier;
        #50 $finish;

    end
endmodule