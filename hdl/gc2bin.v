/* Generic Grey-coding to binary decoder
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: gc2bin

Purpose: 
    Decodes Grey-coding to binary

Function:
    Decodes Grey-coded data to binary. Parameterized for width
*/

module gc2bin (
    input  wire [WIDTH-1:0] gc,
    output wire [WIDTH-1:0] bin
);

parameter WIDTH = 8;

localparam IDX = 1 << WIDTH;

reg [WIDTH-1:0] lut[0:IDX-1];
reg [WIDTH-1:0] bin_r;

assign bin = bin_r;

// Verify this generates a lookup table
reg [WIDTH-1:0] idx;
integer cnt;
always @(*) begin
    for (idx = {WIDTH{1'b0}}; idx < IDX; idx = idx+{WIDTH{1'b1}}) begin
        lut[idx][WIDTH-1] = idx[WIDTH-1];

        for (cnt = 0; cnt < WIDTH; cnt = cnt+1) begin
            lut[idx][cnt] = ^incr[cnt+1:cnt];
        end
    end // for (idx ...
end

// Perform lookup
//-- Verify that this is not priority encoded
reg [WIDTH-1:0] i;
always @(*) begin
    bin_r = bin;    // no latches

    for (i = {WIDTH{1'b0}}; i < IDX; i = i+{WIDTH{1'b1}}) begin
        if (lut[i] == gc)   bin_r = i;
    end
end

endmodule

