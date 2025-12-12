`timescale 1ns/1ns
module tb_hierarchical;
    parameter WIDTH = 3;    // The number of bits for the input-output
    parameter BIT_STATE = 2 ** WIDTH;   // The total possible states for the given bit WIDTH

    reg clk, reset, start;

    /*
     * Addition_Control module instantiation
     */
    reg [ WIDTH-1:0 ] add_in1, add_in2;
    wire [ WIDTH-1:0 ] add_out;
    wire add_done, final_carry;

    Addition_Control #( .WIDTH( WIDTH ) ) add_control_instance (
        .clk( clk ),
        .reset( reset ),
        .start( start ),
        .in1( add_in1 ),
        .in2( add_in2 ),
        .out( add_out ),
        .final_carry( final_carry ),
        .done( add_done )
    );

    // Latch the output signals for clearer waveform
    reg [WIDTH-1:0] add_latched;
    reg carry_latched;
    always @(posedge clk) begin
        if( add_done ) begin
            add_latched <= add_out;
            carry_latched <= final_carry;
        end
    end

    /*
     * Subtraction_Control module instantiation
     */
    reg [ WIDTH-1:0 ] sub_in1, sub_in2;
    wire [ WIDTH-1:0 ] sub_out;
    wire sub_done, final_borrow;

    Subtraction_Control #( .WIDTH( WIDTH ) ) sub_control_instance (
        .clk( clk ),
        .reset( reset ),
        .start( start ),
        .in1( sub_in1 ),
        .in2( sub_in2 ),
        .out( sub_out ),
        .final_borrow( final_borrow ),
        .done( sub_done )
    );

    // Latch the output signals for clearer waveform
    reg [WIDTH-1:0] sub_latched;
    reg borrow_latched;
    always @(posedge clk) begin
        if( sub_done ) begin
            sub_latched <= sub_out;
            borrow_latched <= final_borrow;
        end
    end

    /*
     * Multiplier_Control module instantiation
     */
    reg [ WIDTH-1:0 ] mul_in1, mul_in2;
    wire [ WIDTH-1:0 ] mul_high, mul_low;
    wire mul_done;

    Multiplier_Control #( .WIDTH( WIDTH ) ) mul_control_instance (
        .clk( clk ),
        .reset( reset ),
        .start( start ),
        .in1( mul_in1 ),
        .in2( mul_in2 ),
        .out_high( mul_high ),
        .out_low( mul_low ),
        .done( mul_done )
    );

    // Latch the output signals for clearer waveform
    reg [WIDTH-1:0] high_latched, low_latched;
    always @(posedge clk) begin
        if( mul_done ) begin
            high_latched <= mul_high;
            low_latched <= mul_low;
        end
    end

    /* 
     * Divider_Control module instantiation
     */
    reg [ WIDTH-1:0 ] div_in1, div_in2;
    wire [ WIDTH-1:0 ] quotient, remainder;
    wire div_done;

    Divider_Control #( .WIDTH( WIDTH ) ) div_control_instance (
        .clk( clk ),
        .reset( reset ),
        .start( start ),
        .in1( div_in1 ),
        .in2( div_in2 ),
        .quotient( quotient ),
        .remainder( remainder ),
        .done( div_done )
    );

    // Latch the output signals for clearer waveform
    reg [WIDTH-1:0] q_latched, r_latched;
    always @(posedge clk) begin
        if( div_done ) begin
            q_latched <= quotient;
            r_latched <= remainder;
        end
    end

    // Sequential ALU Control
    reg [ WIDTH-1:0 ] alu_in1, alu_in2, opcode;
    wire [ WIDTH-1:0 ] alu_high, alu_low;
    wire alu_done, alu_flag;

    Hierarchical_ALU #( .WIDTH( WIDTH ) ) alu_control_instance (
        .clk( clk ),
        .reset( reset ),
        .start( start ),
        .opcode( opcode ),
        .in1( alu_in1 ),
        .in2( alu_in2 ),
        .out_high( alu_high ),
        .out_low( alu_low ),
        .flag( alu_flag ),
        .done( alu_done )
    );

    // Latch the output signals for clearer waveform
    reg [WIDTH-1:0] p_high_latched, p_low_latched;
    reg flag_latched;
    always @(posedge clk) begin
        if( alu_done ) begin
            p_high_latched <= alu_high;
            p_low_latched <= alu_low;
            flag_latched <= alu_flag;
        end
    end

    // Generate the clock signal
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Tests for the Individual ALU Control modules
    `define GENERIC_CONTROL( REG1, REG2, CLK, RESET, START, DONE ) \
    begin \
        RESET = 1'b0; START = 1'b0; \
        REG1 = { WIDTH{ 1'b0 } }; \
        repeat( BIT_STATE ) begin \
            REG2 = { WIDTH{ 1'b0 } }; \
            repeat( BIT_STATE ) begin \
                RESET = 1'b1; @( posedge CLK ); \
                RESET = 1'b0; @( posedge CLK ); \
                @( posedge CLK ); \
                START = 1'b1; @( posedge CLK ); \
                START = 1'b0; \
                wait( DONE ); \
                @( posedge CLK ); @( posedge CLK ); \
                REG2 = REG2 + 1; @( posedge CLK ); \
            end \
            REG1 = REG1 + 1; @( posedge CLK ); \
        end \
        REG1 = {WIDTH{1'b0}}; \
        REG2 = {WIDTH{1'b0}}; \
    end

    // Test for the Overhead ALU Control module
    `define GENERIC_OPERATIONS( OP, REG1, REG2, CLK, RESET, START, DONE ) \
    begin \
        OP = 1'b0; \
        repeat( BIT_STATE ) begin \
            RESET = 1'b0; START = 1'b0; \
            REG1 = { WIDTH{ 1'b0 } }; \
            repeat( BIT_STATE ) begin \
                REG2 = { WIDTH{ 1'b0 } }; \
                repeat( BIT_STATE ) begin \
                    RESET = 1'b1; @( posedge CLK ); \
                    RESET = 1'b0; @( posedge CLK ); \
                    @( posedge CLK ); \
                    START = 1'b1; @( posedge CLK ); \
                    START = 1'b0; \
                    wait( DONE ); \
                    @( posedge CLK ); @( posedge CLK ); \
                    REG2 = REG2 + 1; @( posedge CLK ); \
                end \
                REG1 = REG1 + 1; @( posedge CLK ); \
            end \
            REG1 = {WIDTH{1'b0}}; \
            REG2 = {WIDTH{1'b0}}; \
            OP = OP + 1; \
        end\
    end

    initial begin
        $dumpfile( "waveform7.vcd" );
        $dumpvars( 0, tb_hierarchical );

        `GENERIC_OPERATIONS( opcode, alu_in1, alu_in2, clk, reset, start, alu_done );

        #50 $finish;
    end
endmodule