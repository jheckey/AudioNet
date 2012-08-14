/*
Author: Jeff Heckey (jheckey@gmail.com)
Copyright: 2011, all rights reserved

Module: p2tdm

Purpose:
    Translate parallel data from a 256-bit wide register into serial, 
    8-channel, 32-bit word TDM format output to the DAC

Function:
    
*/

module p2tdm (
    input  wire         clk,            // system clock
    input  wire         rstn,           // async, active low reset

    input  wire         enable,         // enable de-serializer
    input  wire         valid,          // valid for pdata
    output wire         ack,            // acknowledging data
    input  wire [255:0] pdata,          // parallel data for samples
    
    input  wire         sclk,           // TDM serial clock
    input  wire         srstn,          // TDM clk synced reset
    output wire         fs,             // TDM frame sync
    output wire         tdmout,         // TDM data out

    output reg          retransIncr,    // count of samples retransmitted
    output reg          droppedIncr     // count of samples dropped
);

reg         lastCnt;
reg [255:0] tdata;
reg         acked;
reg         pFs;
reg         pTdmout;

wire        clear;
wire [7:0]  gc;
wire [7:0]  sgc;
wire [7:0]  cnt;

wire        next;
wire [7:0]  align;

assign next  = enable && (cnt != lastCnt);
assign ack   = next && (cnt == 8'd0);
assign align = cnt - 8'd1;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        lastCnt <= 8'd255;
        acked   <= 1'b0;
        tdata   <= 256'd0;

        pFs      <= 1'b0;
        pTdmout  <= 1'b0;

        retransIncr <= 1'b0;
        droppedIncr <= 1'b0;
    end
    else begin
        // Update interal flops
        lastCnt <= cnt;
        acked   <= (ack) ? 1'b1 : (valid) ? 1'b0 : acked;
        tdata   <= (ack) ? pdata : tdata;

        // Update output
        pFs      <= (next) ? align[7] : fs;
        pTdmout  <= (next) ? tdata[cnt] : tdmout;

        // Count error events
        retransIncr <=  acked && ack;
        droppedIncr <= !acked && valid;
    end
end

/********************
  Generate and synchronize counter
********************/
syncFlop #(.FLOPS(2)) syncClear (.clk(sclk), .rstn(srstn), .data(!enable), .sync(clear));

gcCntr8 gcCntr (.clk(sclk), .rstn(rstn), .clear(clear), .cntr(), .gc(gc));

genvar i;
generate
    for (i=0; i<8; i=i+1) begin : GEN_SYNC
        syncFlop #(.FLOPS(2)) gcSync (.clk(clk), .rstn(rstn), .data(gc[i]), .sync(sgc[i]));
    end
endgenerate

gc2bin8 gc2b (.gc(sgc), .bin(cnt));

/****************
  Retime output
****************/
syncFlop syncFs (.clk(sclk), .rstn(srstn), .data(pFs), .sync(fs));
syncFlop syncTdm (.clk(sclk), .rstn(srstn), .data(pTdmout), .sync(tdmout));


endmodule

