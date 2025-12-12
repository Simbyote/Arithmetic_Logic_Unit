/*
 * hierarchical_alu.v
 *
 * Purpose:
 * - Implement a hierarchical ALU that performs arithmetic and logical operations based on the opcode
 *   using a combinational output selector and sequential sub-controllers for multi-cycle operations. 
 *
 * Modules Included:
 * - Hierarchical_ALU: Combinational output selector that coordinates sub-controllers
 * - Addition_Control: Sequential FSM controller for bit-serial addition
 * - Subtraction_Control: Sequential FSM controller for bit-serial subtraction
 * - Multiplier_Control: Sequential FSM controller for shift-and-add multiplication
 * - Divider_Control: Sequential FSM controller for restoring division
 *
 * Parameters:
 * - WIDTH: The bit-width of the input and output signals
 *
 * Implementation:
 * - The "Hierarchical_ALU" is the top-level module that uses a combinational case statement to select
 *   outputs from instatiated sub-controllers and combinational modules based on the opcode
 * - The multi-cycle operations ("Addition_Control", "Subtraction_Control", "Multiplier_Control", and 
 *   "Divider_Control") use sequential FSM-based  controllers
 * - Single-cycle operations (shifting, logic gates, and comparators) use purely combinational logic
 * - All sub-controllers operate in parallel with the top-level "Hierarchical_ALU" multiplexes their outputs
 */

/*
 * Hierarchical_ALU

 * Purpose: 
 * - Top-level combinational output selector for ALU operations
 *
 * Note:
 * - This module is is not a part of a FSM and is purely combinational (indicated by "always@(*)" block)
 * - All sub-controllers are instantiated and run in parallel
 * - The opcode input selects which controller's output to forward
 * - Sequential control happens within the sub-controllers and not within this top-level module
 * - Single-cycle operations complete immediately
 * - Multi-cycle operations complete when a sub-controller asserts the "done" signal
 */
module Hierarchical_ALU #( parameter WIDTH = 4 ) (
    // Inputs passed into sub-controllers
    input wire clk,     // Clock input
    input wire reset,   // Reset input
    input wire start,   // Start input

    input wire [ 3:0 ] opcode,
    input wire [ WIDTH-1:0 ] in1, 
    input wire [ WIDTH-1:0 ] in2,
    output reg [ WIDTH-1:0 ] out_high,   // Multiplication, a remainder, or shift overflow
    output reg [ WIDTH-1:0 ] out_low, // Quotient, sum, difference, or shift result
    output reg flag,    // Carry or Borrow flag
    output reg done     // Completion flag
);
    // Opcode definitions
    localparam [ 3:0 ]  
        // Multi-cycle operations
        ADD = 4'b0000,
        SUB = 4'b0001,
        MUL = 4'b0010,
        DIV = 4'b0011,
        // Single-cycle operations
        SHL = 4'b0100,
        SHA = 4'b0101,
        LT  = 4'b0110,
        GT  = 4'b0111,
        EQ  = 4'b1000,
        AND = 4'b1001,
        OR  = 4'b1010,
        XOR = 4'b1011,
        NOT = 4'b1100;

    // ============== Multi-cycle Sequential Sub-Controllers ==============
    // ====== All sub-controllers use a bit-serial FSM implementation =======

    // Addition Controller 
    wire [ WIDTH-1:0 ] add_out;
    wire add_done, final_carry;

    Addition_Control #( .WIDTH( WIDTH ) ) adder_instance (
        .clk( clk ),
        .reset( reset ),
        .start( start ),
        .in1( in1 ),
        .in2( in2 ),
        .out( add_out ),
        .final_carry( final_carry ),
        .done( add_done )
    );

    // Subtraction Controller
    wire [ WIDTH-1:0 ] sub_out;
    wire sub_done, final_borrow;

    Subtraction_Control #( .WIDTH( WIDTH ) ) subtractor_instance (
        .clk( clk ),
        .reset( reset ),
        .start( start ),
        .in1( in1 ),
        .in2( in2 ),
        .out( sub_out ),
        .final_borrow( final_borrow ),
        .done( sub_done )
    );

    // Multiplier Controller
    wire [ WIDTH-1:0 ] mul_low, mul_high;
    wire mult_done;

    Multiplier_Control #( .WIDTH( WIDTH ) ) multiplier_instance (
        .clk( clk ),
        .reset( reset ),
        .start( start ),
        .in1( in1 ),
        .in2( in2 ),
        .out_high( mul_high ),
        .out_low( mul_low ),
        .done( mult_done )
    );

    // Divider Controller
    wire [ WIDTH-1:0 ] div_quotient, div_remainder;
    wire div_done;
    
    Divider_Control #( .WIDTH( WIDTH ) ) divider_instance (
        .clk( clk ),
        .reset( reset ),
        .start( start ),
        .in1( in1 ),
        .in2( in2 ),
        .quotient( div_quotient ),
        .remainder( div_remainder ),
        .done( div_done )
    );

    // ============== Single-cycle Combinational Sub-Controllers ==============
    // ====== All sub-controllers use a combinational implementation =======

    // Logical Shift Left
    wire [ WIDTH-1:0 ] shl_out, shl_overflow;

    nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shl_instance (
        .in( in1 ),
        .shift( in2 ),
        .out( shl_out ),
        .overflow( shl_overflow )
    );

    // Arithmetic Shift Right
    wire [ WIDTH-1:0 ] shr_out, shr_overflow;

    nBit_Shift #( .WIDTH( WIDTH ), .OP( 1 ) ) shr_instance (
        .in( in1 ),
        .shift( in2 ),
        .out( shr_out ),
        .overflow( shr_overflow )
    );

    // Less than Comparator
    wire lt_out;
    
    Less_Than #( .WIDTH( WIDTH ) ) lt_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( lt_out )
    );

    // Greater than Comparator
    wire gt_out;

    Greater_Than #( .WIDTH( WIDTH ) ) gt_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( gt_out )
    );

    // Equal to Comparator
    wire eq_out;

    Equal_To #( .WIDTH( WIDTH ) ) eq_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( eq_out )
    );

    // bit-serial AND Gate
    wire [ WIDTH-1:0 ] and_out;

    nBit_AND #( .WIDTH( WIDTH ) ) and_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( and_out )
    );

    // bit-serial OR Gate
    wire [ WIDTH-1:0 ] or_out;

    nBit_OR #( .WIDTH( WIDTH ) ) or_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( or_out )
    );

    // bit-serial XOR Gate
    wire [ WIDTH-1:0 ] xor_out;

    nBit_XOR #( .WIDTH( WIDTH ) ) xor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( xor_out )
    );

    // bit-serial NOT Gate
    wire [ WIDTH-1:0 ] not_out;
    
    nBit_NOT #( .WIDTH( WIDTH ) ) not_instance (
        .in( in1 ),
        .out( not_out )
    );

    // ============== Combinational Output Multiplexer ======================
    // Combinational case statement that selects which operation's output to forward
    // based on the opcode input 
    always @(*) begin
        // Defaults outputs )prevents latches)
        out_high = { WIDTH{ 1'b0 } };
        out_low = { WIDTH{ 1'b0 } };
        flag = 1'b0;
        done = 1'b0;

        // Multi-cycle operations "done" signal waits for the its corresponding sub-controller to assert it
        // Single-cycle operations ""done" signal are completed immediately
        case( opcode )
            ADD: begin
                out_low = add_out;
                flag = final_carry;
                done = add_done;
            end
            SUB: begin
                out_low = sub_out;
                flag = final_borrow;
                done = sub_done;
            end
            MUL: begin
                out_high = mul_high;
                out_low = mul_low;
                done = mult_done;
            end
            DIV: begin
                out_high = div_quotient;
                out_low = div_remainder;
                done = div_done;
            end
            SHL: begin
                out_high = shl_out;
                out_low = shl_overflow;
                done = 1'b1;
            end
            SHA: begin
                out_high = shr_out;
                out_low = shr_overflow;
                done = 1'b1;
            end
            LT: begin
                flag = lt_out;
                done = 1'b1;
            end
            GT: begin
                flag = gt_out;
                done = 1'b1;
            end
            EQ: begin
                flag = eq_out;
                done = 1'b1;
            end
            AND: begin
                out_low = and_out;
                done = 1'b1;
            end
            OR: begin
                out_low = or_out;
                done = 1'b1;
            end
            XOR: begin
                out_low = xor_out;
                done = 1'b1;
            end
            NOT: begin
                out_low = not_out;
                done = 1'b1;
            end
            default: begin
                done = 1'b1;    // An unsupported opcode - immediately completes
            end
        endcase
    end
endmodule

/*
 * Addition_Control
 *
 * Purpose:
 * - Sequential FSM controller for bit-serial addition
 *
 * Note:
 * - Utilizes state registers and a posedge clock
 * - Performs addition one bit per clock cycle (i.e. bit-serial implementation)
 * - States: INIT -> STEP <-> LOAD -> DONE -> INIT (cycled)
 * - Takes WIDTH clock cycles to complete WIDTH-bit addition
 */
module Addition_Control #( parameter WIDTH = 4 ) (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output reg [ WIDTH-1:0 ] out,
    output reg final_carry,
    output reg done
);
    // FSM states
    localparam [ 1:0 ] 
        INIT = 2'b00,
        STEP = 2'b01,
        LOAD = 2'b10,
        DONE = 2'b11;
    reg [ 1:0 ] state;

    // Internal registers
    reg [ WIDTH-1:0 ] final_out;
    reg current_in1;
    reg current_in2;
    reg carry_in;
    reg [ WIDTH-2:0 ] step_counter;

    // Addition control signals
    wire current_out;
    wire carry_out;

    // Full Adder instance
    Addition_Core #( .WIDTH( WIDTH ) ) adder_instance (
        .in1( current_in1 ),
        .in2( current_in2 ),
        .carry_in( carry_in ),
        .out( current_out ),
        .carry_out( carry_out )
    );

    // FSM logic - triggered by posedge clk
    always @( posedge clk or posedge reset ) begin
        if( reset ) begin
            out <= { WIDTH{ 1'b0 } };
            final_carry <= 1'b0;
            final_out <= { WIDTH{ 1'b0 } };
            current_in1 <= 1'b0;
            current_in2 <= 1'b0;
            carry_in <= 1'b0;
            step_counter <= 0;
            done <= 1'b0;
            state <= STEP;
        end else begin
            case( state )
                INIT: begin // Initialize the addition operation
                    done <= 1'b0;
                    if( start ) begin
                        step_counter <= 0;
                        current_in1 <= in1[ 0 ];
                        current_in2 <= in2[ 0 ];
                        carry_in <= 1'b0;
                        state <= LOAD;
                    end
                end
                STEP: begin // Perform the addition operation
                    if( step_counter < WIDTH ) begin
                        current_in1 <= in1[ step_counter ];
                        current_in2 <= in2[ step_counter ];
                        carry_in <= carry_out;
                        state <= LOAD;
                    end else begin
                        out <= final_out;
                        final_carry <= carry_out;
                        state <= DONE;
                    end
                end
                LOAD: begin // Load the output registers
                    final_out[ step_counter ] <= current_out;
                    state <= STEP;
                    step_counter <= step_counter + 1;

                end
                DONE: begin // Finish the addition operation
                    done <= 1'b1;
                    state <= INIT;
                end
            endcase
        end
    end
endmodule

/*
 * Subtraction_Control
 *
 * Purpose: 
 * - Sequential FSM controller for bit-serial subtraction
 *
 * Note:
 * - Utilizes state registers and a posedge clock
 * - Performs subtraction one bit per clock cycle (i.e. bit-serial implementation)
 * - States: INIT -> STEP <-> LOAD -> DONE -> INIT (cycled)
 * - Takes WIDTH clock cycles to complete WIDTH-bit subtraction
 */
module Subtraction_Control #( parameter WIDTH = 4 ) (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output reg [ WIDTH-1:0 ] out,
    output reg final_borrow,
    output reg done
);
    // FSM states
    localparam [ 1:0 ] 
        INIT = 2'b00,
        STEP = 2'b01,
        LOAD = 2'b10,
        DONE = 2'b11;
    reg [ 1:0 ] state;

    // Internal registers
    reg [ WIDTH-1:0 ] final_out;
    reg current_in1;
    reg current_in2;
    reg borrow_in;
    reg [ WIDTH-2:0 ] step_counter;

    // Subtraction control signals
    wire current_out;
    wire borrow_out;

    // Full Subtractor instance
    Subtraction_Core #( .WIDTH( WIDTH ) ) subtractor_instance (
        .in1( current_in1 ),
        .in2( current_in2 ),
        .borrow_in( borrow_in ),
        .out( current_out ),
        .borrow_out( borrow_out )
    );

    // FSM logic
    always @( posedge clk or posedge reset ) begin
        if( reset ) begin
            out <= { WIDTH{ 1'b0 } };
            final_borrow <= 1'b0;
            final_out <= { WIDTH{ 1'b0 } };
            current_in1 <= 1'b0;
            current_in2 <= 1'b0;
            borrow_in <= 1'b0;
            step_counter <= 0;
            done <= 1'b0;
            state <= STEP;
        end else begin
            case( state )
                INIT: begin // Initialize the subtraction operation
                    done <= 1'b0;
                    if( start ) begin
                        step_counter <= 0;
                        current_in1 <= in1[ 0 ];
                        current_in2 <= in2[ 0 ];
                        borrow_in <= 1'b0;
                        state <= LOAD;
                    end
                end
                STEP: begin // Perform the subtraction operation
                    if( step_counter < WIDTH ) begin
                        current_in1 <= in1[ step_counter ];
                        current_in2 <= in2[ step_counter ];
                        borrow_in <= borrow_out;
                        state <= LOAD;
                    end else begin
                        out <= final_out;
                        final_borrow <= borrow_out;
                        state <= DONE;
                    end
                end
                LOAD: begin // Load the output registers
                    final_out[ step_counter ] <= current_out;
                    state <= STEP;
                    step_counter <= step_counter + 1;
                end
                DONE: begin // Finish the subtraction operation
                    done <= 1'b1;
                    state <= INIT;
                end
            endcase
        end
    end
endmodule

/*
 * Multiplier_Control
 *
 * Purpose: 
 * - Sequential FSM controller for shift-and-add multiplication
 *
 * Note:
 * - Utilizes state registers and a posedge clock
 * - Performs multiplication using shift-and-add algorithm (similar to long multiplication)
 * - States: IDLE -> INIT -> STEP (loop) -> DONE -> IDLE
 * - Takes WIDTH clock cycles to complete WIDTH-bit multiplication
 * - Produces a 2*WIDTH bit result, split between out_high and out_low
 */
module Multiplier_Control #( parameter WIDTH = 4 ) (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output reg [ WIDTH-1:0 ] out_high,
    output reg [ WIDTH-1:0 ] out_low,
    output reg done
);
    // FSM states
    localparam [ 1:0 ] IDLE = 2'b00,
                    INIT = 2'b01,
                    STEP = 2'b10,
                    DONE = 2'b11;
    reg [ 1:0 ] state;

    // Internal registers
    reg [ WIDTH-1:0 ] current_out_high;
    reg [ WIDTH-1:0 ] current_out_low;
    reg [ WIDTH-2:0 ] step_counter;

    // Multiplier control signals
    wire [ WIDTH-1:0 ] mul_low, mul_high;
    wire is_equal;

    // Multiplier_Core instance
    Multiplier_Core #( .WIDTH( WIDTH ) ) multiplier_core_instance (
        .in1( in1 ),
        .in2( in2 ),
        .partial_low( current_out_low ),
        .partial_high( current_out_high ),
        .step_counter( step_counter ),
        .out_low( mul_low ),
        .out_high( mul_high ),
        .is_equal( is_equal )
    );

    // FSM logic
    always @( posedge clk or posedge reset ) begin
        if( reset ) begin
            out_high <= { WIDTH{ 1'b0 } };
            out_low <= { WIDTH{ 1'b0 } };
            current_out_high <= { WIDTH{ 1'b0 } };
            current_out_low <= { WIDTH{ 1'b0 } };
            step_counter <= 0;
            done <= 1'b0;
            state <= IDLE;
        end else begin
            case( state )
                IDLE: begin // Initialize the multiplication operation
                    done <= 1'b0;
                    if( start ) begin
                        current_out_high <= { WIDTH{ 1'b0 } };
                        current_out_low <= { WIDTH{ 1'b0 } };
                        state <= INIT;
                    end
                end
                INIT: begin // Perform first multiplication step
                    if( is_equal ) begin
                        current_out_high <= { WIDTH{ 1'b0 } };
                        current_out_low <= in1;
                        state <= STEP;
                    end else begin
                        current_out_high <= { WIDTH{ 1'b0 } };
                        current_out_low <= { WIDTH{ 1'b0 } };
                        state <= STEP;
                    end
                    step_counter <= 1;
                end
                STEP: begin // Remaining multiplication steps
                    if( step_counter < WIDTH ) begin
                        if( is_equal ) begin
                            current_out_high <= mul_high;
                            current_out_low <= mul_low;
                        end

                        step_counter <= step_counter + 1;
                    end else begin
                        out_high <= current_out_high;
                        out_low <= current_out_low;
                        state <= DONE;
                    end
                end
                DONE: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

/*
 * Divider_Control

 * Purpose: 
 * - Sequential FSM controller for restoring division
 *
 * Note:
 * - Utilizes state registers and a posedge clock
 * - Performs division using the restoring algorithm (similar to long division)
 * - States: IDLE -> INIT -> STEP (loop) -> DONE -> IDLE
 * - Takes WIDTH clock cycles to complete WIDTH-bit division
 * - Produces quotient and remainder outputs, split between out_high and out_low respectively
 * - Handles edge cases: division by zero and dividend < divisor
 */
module Divider_Control #( parameter WIDTH = 4 ) (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output reg [ WIDTH-1:0 ] quotient,
    output reg [ WIDTH-1:0 ] remainder,
    output reg done
);
    // FSM states
    localparam [ 1:0 ] IDLE = 2'b00,
                    INIT = 2'b01,
                    STEP = 2'b10,
                    DONE = 2'b11;
    
    reg [ 1:0 ] state;

    // Internal registers
    reg [ WIDTH-1:0 ] current_remainder;
    reg [ WIDTH-1:0 ] current_quotient;
    reg [ WIDTH-1:0 ] divisor;
    reg [ WIDTH-1:0 ] step_result;
    reg [ $clog2( WIDTH )-1:0 ] step_counter;

    // Divider control signals
    wire [ WIDTH-1:0 ] div_quotient, div_remainder;
    wire is_zero, is_less, has_borrow;

    // Divider_Core instance
    Divider_Core #( .WIDTH( WIDTH ) ) divider_core_instance (
        .in1( current_remainder ),
        .in2( divisor ),
        .out( div_quotient ),
        .remainder( div_remainder ),
        .is_zero( is_zero ),
        .is_less( is_less ),
        .has_borrow( has_borrow )
    );

    // FSM logic
    always @( posedge clk or posedge reset ) begin
        if( reset ) begin
            quotient <= { WIDTH{ 1'b0 } };
            remainder <= { WIDTH{ 1'b0 } };
            current_quotient <= { WIDTH{ 1'b0 } };
            current_remainder <= { WIDTH{ 1'b0 } };
            divisor <= { WIDTH{ 1'b0 } };
            step_counter <= 0;
            done <= 1'b0;
            state <= IDLE;
        end else begin
            case( state )
                IDLE: begin // Initialize the division operation
                    done <= 1'b0;
                    if( start ) begin
                        divisor <= in2;
                        current_remainder <= in1;
                        current_quotient <= { WIDTH{ 1'b0 } };
                        step_counter <= WIDTH;
                        state <= INIT;
                    end
                end
                INIT: begin // Perform first division step
                    if( is_zero ) begin
                        current_quotient <= { WIDTH{ 1'b0 } };
                        current_remainder <= { WIDTH{ 1'b0 } };
                        state <= DONE;
                    end else if( has_borrow && !is_zero && !is_less ) begin
                        current_quotient <= div_quotient;
                        current_remainder <= div_remainder;
                        state <= STEP;
                    end else begin
                        current_quotient <= { WIDTH{ 1'b0 } };
                        current_remainder <= in1;
                        state <= DONE;
                    end
                    step_counter <= step_counter - 1;
                end
                STEP: begin // Remaining division steps
                    if( has_borrow && !is_zero && !is_less ) begin
                        current_quotient <= current_quotient + div_quotient;
                        current_remainder <= div_remainder;
                    end else if( is_zero ) begin
                        current_quotient <= { WIDTH{ 1'b0 } };
                        current_remainder <= { WIDTH{ 1'b0 } };
                    end

                    if( step_counter == 0 ) begin
                        state <= DONE;
                    end else begin
                        step_counter <= step_counter - 1;
                    end
                end
                DONE: begin
                    quotient <= current_quotient;
                    remainder <= current_remainder;
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule