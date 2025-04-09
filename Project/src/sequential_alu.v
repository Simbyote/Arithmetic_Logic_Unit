/*
 * sequential_alu.v
 *
 * Purpose:
 * - Implement a sequential arithmetic logic unit (ALU) that performs arithmetic operations
 *   based on the opcode.
 *
 * Modules Included:
 * - Sequential_ALU: Controls the arithmetic operations based on the opcode
 * - Addition_Control: Controls the addition operation
 * - Subtraction_Control: Controls the subtraction operation
 * - Multiplier_Control: Controls the multiplication operation
 * - Divider_Control: Controls the division operation
 *
 * Parameters:
 * - WIDTH: The bit-width of the input and output signals
 * - OP: The operation to be performed (0 for shift left, 1 for shift right)
 *
 * Implementation:
 * - The "Sequential_ALU" module controls the arithmetic operations based on the opcode using a finite state machine
 * - The "Addition_Control" module controls the addition operation using a finite state machine
 * - The "Subtraction_Control" module controls the subtraction operation using a finite state machine
 * - The "Multiplier_Control" module controls the multiplication operation using a finite state machine
 * - The "Divider_Control" module controls the division operation using a finite state machine
 */

/*
 * ALU_Control
 * Purpose: 
 * - Controls the arithmetic operations based on the opcode
 *
 * Note:
 * - The ALU_Control module is a sequential controller that controls the arithmetic operations
 *   based on the opcode. The module is responsible for controlling the addition, subtraction,
 *   multiplication, division, shift left, and shift right operations.
 * - The module uses the Addition_Control, Subtraction_Control, Multiplier_Control, Divider_Control,
 *   and nBit_Shift modules to perform the arithmetic operations.
 * - The module uses a FSM to control the arithmetic operations.
 */
module Sequential_ALU #( parameter WIDTH = 4 ) (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [ 3:0 ] opcode,
    input wire [ WIDTH-1:0 ] in1,
    input wire [ WIDTH-1:0 ] in2,
    output reg [ WIDTH-1:0 ] out_high,   // Can represent the high output of multiplication, the remainder, or shift overflow
    output reg [ WIDTH-1:0 ] out_low, // Can represent the quotient, sum, difference, or shift result
    output reg flag,    // Can represent the carry and borrow flags
    output reg done
);
    // ALU Operations
    localparam [ 3:0 ]  ADD = 4'b0000,
                    SUB = 4'b0001,
                    MUL = 4'b0010,
                    DIV = 4'b0011,
                    SHL = 4'b0100,
                    SHR = 4'b0101,
                    LT  = 4'b0110,
                    GT  = 4'b0111,
                    EQ  = 4'b1000,
                    AND = 4'b1001,
                    OR  = 4'b1010,
                    XOR = 4'b1011,
                    NOT = 4'b1100;
    reg [ 3:0 ] state;

    // Internal wires

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

    // Shift Left Controller
    wire [ WIDTH-1:0 ] shl_out, shl_overflow;

    nBit_Shift #( .WIDTH( WIDTH ), .OP( 0 ) ) shl_instance (
        .in( in1 ),
        .shift( in2 ),
        .out( shl_out ),
        .overflow( shl_overflow )
    );

    // Shift Right Controller
    wire [ WIDTH-1:0 ] shr_out, shr_overflow;

    nBit_Shift #( .WIDTH( WIDTH ), .OP( 1 ) ) shr_instance (
        .in( in1 ),
        .shift( in2 ),
        .out( shr_out ),
        .overflow( shr_overflow )
    );

    // Less than Controller
    wire lt_out;
    
    Less_Than #( .WIDTH( WIDTH ) ) lt_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( lt_out )
    );

    // Greater than Controller
    wire gt_out;

    Greater_Than #( .WIDTH( WIDTH ) ) gt_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( gt_out )
    );

    // Equal Controller
    wire eq_out;

    Equal_To #( .WIDTH( WIDTH ) ) eq_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( eq_out )
    );

    // AND Controller
    wire [ WIDTH-1:0 ] and_out;
    nBit_AND #( .WIDTH( WIDTH ) ) and_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( and_out )
    );

    // OR Controller
    wire [ WIDTH-1:0 ] or_out;
    nBit_OR #( .WIDTH( WIDTH ) ) or_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( or_out )
    );

    // XOR Controller
    wire [ WIDTH-1:0 ] xor_out;
    nBit_XOR #( .WIDTH( WIDTH ) ) xor_instance (
        .in1( in1 ),
        .in2( in2 ),
        .out( xor_out )
    );

    // NOT Controller
    wire [ WIDTH-1:0 ] not_out;
    nBit_NOT #( .WIDTH( WIDTH ) ) not_instance (
        .in( in1 ),
        .out( not_out )
    );

    // FSM logic
    always @(*) begin
        // Initialize the output signals
        out_high = { WIDTH{ 1'b0 } };
        out_low = { WIDTH{ 1'b0 } };
        flag = 1'b0;
        done = 1'b0;

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
            SHR: begin
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
                done = 1'b1;
            end
        endcase
    end
endmodule

/*
 * Addition_Control
 *
 * Purpose: Controls the addition operation
 *
 * Note:
 * - The Addition_Control module is a sequential controller that controls the addition operation.
 * - The module uses the Addition_Core module to perform the addition operation.
 * - The module uses a FSM to control the addition operation.
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
    localparam [ 1:0 ] INIT = 2'b00,
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

    // FSM logic
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
 * Purpose: Controls the subtraction operation
 *
 * Note:
 * - The Subtraction_Control module is a sequential controller that controls the subtraction operation.
 * - The module uses the Subtraction_Core module to perform the subtraction operation.
 * - The module uses a FSM to control the subtraction operation.
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
    localparam [ 1:0 ] INIT = 2'b00,
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
 * - Controls the multiplication operation
 *
 * Note:
 * - The Multiplier_Control module is a sequential controller that controls the multiplication operation.
 * - The module uses the Multiplier_Core module to perform the multiplication operation.
 * - The module uses a FSM to control the multiplication operation.
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
 * - Controls the division operation
 *
 * Note:
 * - The Divider_Control module is a sequential controller that controls the division operation.
 * - The module uses the Divider_Core module to perform the division operation.
 * - The module uses a FSM to control the division operation.
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