/*
 * checks.v
 * This file contains a collection of parameter checks for program-wide use
 *
 * Purpose:
 * - These modules provide compile-time checks for the parameters used in the project
 *
 * Modules Included:
 * - Width_Check: Ensures a proper WIDTH input
 * - Set_Check: Ensures a proper SET input
 *
 * Parameters Checked:
 * - WIDTH: The bit width of the input-output
 * - SET: The number of test cases to run
 */

/*
 * Width_Check
 *
 * Purpose:
 * - Checks the validity of the WIDTH parameter value
 *
 * Note:
 * - WIDTH has a lower limit of 1 and an upper limit of 1024
 * - Includes a warning if WIDTH exceeds 256
 */
module Width_Check #( parameter WIDTH = 1 );
    initial begin
        if( WIDTH < 1 ) begin
            $error( "Error: Invalid WIDTH value (%0d). Must be greater than 0", WIDTH );
        end
        else if( WIDTH > 256 ) begin
            $warning( "Warning: WIDTH value (%0d) exceeds recommended limit (256)", WIDTH );
        end
        else if( WIDTH > 1024 ) begin
            $error( "Error: WIDTH value (%0d) exceeds maximum limit (1024)", WIDTH );
        end
    end
endmodule

/*
 * Set_Check
 * 
 * Purpose:
 * - Checks the validity of the SET parameter value
 *
 * Note:
 * - SET has a lower limit of 1 and an upper limit of 1000
 * - Includes a warning if SET exceeds 500
 */
module Set_Check #( parameter SETS = 1 );
    initial begin
        if( SETS < 1 ) begin
            $error( "Error: Invalid SET value (%0d). Must be greater than 0", SETS );
        end
        else if( SETS > 500 ) begin
            $warning( "Warning: SET value (%0d) exceeds recommended limit (500)", SETS );
        end
        else if( SETS > 1000 ) begin
            $error( "Error: SET value (%0d) exceeds maximum limit (1000)", SETS );
        end
    end
endmodule