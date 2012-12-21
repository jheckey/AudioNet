/* reset synchronizer
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: resetSync

Purpose: 
    Simple, variable depth reset synchronizer flop

Function:
*/

module resetSync (
    input  wire     clk,
    input  wire     asyncRstn,
    output wire     syncRstn
);

parameter FLOPS = 2;

syncFlop #(.FLOPS(FLOPS)) sync (.clk(clk), .rstn(asyncRstn), .data(1'b1), .sync(syncRstn));

endmodule

