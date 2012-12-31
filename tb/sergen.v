/* serial data generator
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: sergen

Purpose: 
    Randomly generates serial data, creates sfs every 256 bits

Function:
    Creates a random bit at every clock cycle when enabled. Generates an
    sfs (serial frame start) at every 256 bits.

    THIS MODULE IS NOT SYNTHESIZABLE. It is just for verification.
*/

module sergen (
    input  wire     sclk,
    input  wire     rstn,

    input  wire     enable,
    input  wire     directData,
    input  wire     ddata,

    output reg      sdata,      // serial data
    output reg      sfs         // serial frame sync
);

reg [7:0] count;
integer rand;

always @(posedge sclk or negedge rstn)
begin
    if (!rstn) begin
        count   <= 8'd0;
        sdata   <= 1'b0;
        sfs     <= 1'b0;
    end
    else begin
        if (enable) begin
            count   <= count + 8'd1;
            sdata   <= directData ? ddata : {$random} % 2;
            sfs     <= (count == 0) ? 1'b1 : 1'b0;
        end
    end
end

endmodule

