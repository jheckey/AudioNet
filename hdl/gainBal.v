/* Gain and balance multipliers
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: gainBal

Purpose: 
    A gain/balance fixed point multiplier

Function:
    This is a parallel multiplier for all 8 channels of the 256-bit frame.
    It takes the gain and balance, doubles the width of the data, multiplies
    the values and readjusts the width back to 32-bits
*/

module gainBal (
    input  wire             clk,
    input  wire             rstn,

    input  wire             din_val,
    input  wire [255:0]     din,
    input  wire [63:0]      gain,
    input  wire [31:0]      bal,
    output reg              dout_val,
    output reg  [255:0]     dout
);

reg [7:0]  gain_mem[7:0];
reg [7:0]  bal_mem[3:0];
reg [15:0] mult[0:7];
reg [47:0] quot[0:7];
integer i, j, k, l;

always @* begin
    for (l=0; l<8; l=l+1) begin
        gain_mem[l]     = gain[8*l +: 8];
        if (l < 4)
            bal_mem[l]  = bal[8*l +: 8];
    end
end

// Flop each multiplier from configured inputs (one cycle of latency shouldn't matter)
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        for (i=0; i<8; i=i+1) begin
            mult[i] <= 16'd0;
        end
    end
    else begin
        for (i=0; i<4; i=i+1) begin
            // Sign-extend gain and balance to 16-bits, then multiply
            mult[i] <= {{8{gain_mem[2*i  ][7]}}, gain_mem[2*i  ]} * {{8{~bal_mem[i][7]}}, ~bal_mem[i]};
            mult[i] <= {{8{gain_mem[2*i+1][7]}}, gain_mem[2*i+1]} * {{8{ bal_mem[i][7]}},  bal_mem[i]};
        end
    end
end

// Perform multiplication on the incoming DSP data
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dout_val    <= 1'b0;

        for (j=0; j<8; j=j+1) begin
            quot[j] <= 48'd0;
        end
    end
    else begin
        dout_val    <= din_val;

        for (j=0; j<8; j=j+1) begin
            quot[j] <= {16'd0, din[32*j +:32]} * {{32{mult[k][15]}}, mult[k]};
        end
    end
end

// Truncate the lower bits for the output
always @* begin
    for (k=0; k<8; k=k+1) begin
        dout[32*k +:32] = quot[k][47:16];
    end
end

endmodule

