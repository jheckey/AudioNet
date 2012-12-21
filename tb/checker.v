/* checker
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: checker

Purpose: 
    Takes data returned from the DUT and compares it to the expected data

Function:
    When actual data (actData) is received, it is flopped and the head of
    the scoreboard is popped the next cycle. The next cycle, the expected
    data (expData) from the scoreboard is compared to the flopped actual
    data (checkData). If there is a mismatch, an error is printed.

    THIS MODULE IS NOT SYNTHESIZABLE. It is just for verification.
*/

module checker (
    input  wire         clk,
    input  wire         rstn,

    // Data from scoreboard
    input  wire         expValid,
    input  wire [255:0] expData,
    output reg          expPop,

    // data from monitor
    input  wire         actValid,
    input  wire [255:0] actData,

    output reg          testPass
);

reg         testPassN;
reg [255:0] checkData, xorData;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        // default to passing, fail on bad check
        testPass    <= 1'b1;

        expPop      <= 1'b0;
        checkData   <= 256'd0;
    end
    else begin
        testPass    <= testPassN;

        if (actValid) begin
            expPop      <= 1'b1;
            checkData   <= actData;
        end
        else if (expPop) begin
            expPop      <= 1'b0;
        end
    end
end

// Perform check
always @* begin
    testPassN = testPass;
    xorData = expData ^ checkData;

    if (expPop) begin
        if (xorData != 256'd0) begin
            $display ("ERROR: %t: %m data mismatch\n\tExp: %h\n\tAct: %h\n\tXOR: %h", 
                    $time, expData[255:0], checkData[255:0], xorData[255:0]);
            testPassN = 1'b0;
        end
    end
end

endmodule

