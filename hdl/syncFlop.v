/* synchronizer flops
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: syncFlop

Purpose: 
    Simple, variable depth synchronizer flop for data

Function:
    Allows for variable depth meta-stability flops to synchronize between 
    clock domains. 
    
    Should NOT be used for parallel data, only serial data or
    error-correctable/encoded controls
*/

module syncFlop (
    input  wire     clk,
    input  wire     rstn,
    input  wire     data,
    output wire     sync
);

parameter FLOPS = 2;
parameter RESET = 1'b0;

reg [FLOPS-1:0] stage;
integer i;

assign sync = stage[FLOPS-1];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        for (i=0; i<FLOPS; i=i+1) begin
            stage[i]   <= RESET;
        end
    end
    else begin
        stage[0]    <= data;

        for (i=1; i<FLOPS; i=i+1) begin
            stage[i]    <= stage[i-1];
        end
    end
end

endmodule

