/* scoreboard
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: scoreboard

Purpose: 
    Simple, FIFO-based scoreboard.

Function:
    Simply adds any data presented to the FIFO and pops it when requested.
    If an overflow is detected, it will halt the test and recommend
    increasing FIFO depth.

    THIS MODULE IS NOT SYNTHESIZABLE. It is just for verification.
*/

module scoreboard #(
    parameter ADDR = 3,
    parameter DEPTH = 2**ADDR,
    parameter WIDTH = 32
) (
    input  wire         clk,
    input  wire         rstn,

    input  wire             push,
    input  wire             pop,
    input  wire [WIDTH-1:0] din,
    output reg  [DEPTH-1:0] level,
    output reg              empty,
    output reg              full,
    output reg  [WIDTH-1:0] dout
);

reg [WIDTH-1:0] mem[DEPTH-1:0];

integer i, rdPtr, wrPtr;
integer rdPtrN;
integer wrPtrN;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        level   <= {DEPTH{1'b0}};
        rdPtr   <= 0;
        wrPtr   <= 0;

        // Clear memory to 0s
        for (i=0; i<DEPTH; i=i+1) begin
            mem[i]  <= {WIDTH{1'b0}};
        end
    end
    else begin
        if (push && full) begin
            $display ("ERROR: %t: Scoreboard overflow in %m! Resize and rerun", $time);
            $finish;
        end
        else if (push && !full) begin
            mem[wrPtr]  <= din;
            wrPtr       <= wrPtrN;
        end

        if (pop && empty) begin
            $display ("ERROR: %t: Scoreboard popped when empty!", $time);
        end
        else if (pop && !empty) begin
            rdPtr   <= rdPtrN;
        end

        if (push && !pop) begin
            level <= level + 1;
        end
        else if (pop && !push) begin
            level <= level - 1;
        end
    end
end

always @(level, rdPtr, wrPtr) begin
    full    = (level == DEPTH);
    empty   = (level == 0);
    rdPtrN  = (rdPtr + 1) % DEPTH;
    wrPtrN  = (wrPtr + 1) % DEPTH;
    dout    = (empty) ? {WIDTH{1'b0}} : mem[rdPtr];
end

endmodule

