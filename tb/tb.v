/* Top level test
Author: Jeff Heckey (jheckey@gmail.com)
Copyright: 2011, all rights reserved

Module: tb

Purpose: 
    A fully extensible randomized testbench for the AudioNet RTL

Function:
    This testbench is comprised of:
        * sergen - serial data generator
        * serjit - clock jitter generator for the serial data in
        * rectifier - serial to parallel data for serial data
        * scoreboard - FIFOs for storing stimulus and response 
        * checker - compares expected to actual output
        * cpu - register read and write control
*/

`timescale 1ns/1ns

module tb;
// Clocks and resets
reg          clk;
reg          rstn;
reg          hclk;
reg          hresetn;
reg          sclk;


// AHB bus interface
reg          hsel;
reg  [31:0]  haddr;
reg  [2:0]   hburst;
reg          hmastlock;
reg  [2:0]   hsize;
reg  [1:0]   htrans;
reg          hwrite;
reg  [31:0]  hwdata;
wire [31:0]  hrdata;
wire         hready;
wire [1:0]   hresp;

// Serial I/Os
wire         fsin;
wire         tdmin;
wire         fsout;
wire         tdmout;

// TB controls
reg          gclk;
reg          tbrstn;
reg          sergen_en;
reg          passThru;
wire         rxTestPass, txTestPass;
wire         rxPvalid, regPvalid, txPvalid;
wire [255:0] rxPdata, regPdata, txPdata;
wire         rxChkExpEmpty, rxChkExpPop;
wire         txChkExpEmpty, txChkExpPop;
wire [255:0] rxChkExpData, txChkExpData;
wire         rxMonValid, txMonValid;
wire [255:0] rxMonData, txMonData;

/* Dump controls */
initial begin
    $display("%t: Opening dumpfile", $time);
    $dumpfile("/tmp/all.lxt");
    $dumpvars(0,tb);
end

initial begin
    $display("%t: Initializing...", $time);
    clk       = 1'b0;
    sclk      = 1'b0;
    hclk      = 1'b0;
    rstn      = 1'b0;
    hresetn   = 1'b0;
    gclk      = 1'b0;
    tbrstn    = 1'b0;
    sergen_en = 1'b0;

    hsel      = 1'b0;
    haddr     = 32'd0;
    hburst    = 3'd0;
    hmastlock = 1'b0;
    hsize     = 3'd0;
    htrans    = 2'd0;
    hwrite    = 1'b0;
    hwdata    = 32'd0;
    passThru  = 1'b0;

    // wake up TB
    #20
    $display("%t: Waking TB...", $time);
    tbrstn    = 1'b1;

    // wake up DUT
    #20
    $display("%t: Waking DUT...", $time);
    rstn      = 1'b1;
    hresetn   = 1'b1;

    // Initialize registers
    #10
    $display("%t: Initialize DUT...", $time);
    // Enable bypass mode (tdm2p->p2tdm)
    write_reg(32'h0000_0300, 32'h0000_0001);
    passThru = 1'b1;
    $display("bypass enabled");

    // Enable p2tdm
    write_reg(32'h0000_0100, 32'h8000_0000);
    $display("p2tdm enabled");

    // Enable tdm2p, look for the pattern 00111100
    write_reg(32'h0000_0000, 32'h8000_FF3C);
    $display("tdm2p enabled");

    // Start testing
    #10
    $display("%t: Starting serial generation...", $time);
    sergen_en = 1'b1;

    // Finish test
    #30000
    $display("%t: Finished.", $time);
    $finish;
end

always #1   clk  <= ~clk;   // 100  Mhz
always #1   hclk <= ~hclk;  // 100  Mhz
always #8   sclk <= ~sclk;  // 12.5 Mhz

always @(sclk)
    gclk = sclk;


tdm tdm (
    // Clocks and resets
    .clk                    (clk),
    .rstn                   (rstn),
    .hclk                   (hclk),
    .hresetn                (hresetn),
    .sclk                   (sclk),

    // AHB bus interface
    .hsel                   (hsel),
    .haddr                  (haddr),
    .hburst                 (hburst),
    .hmastlock              (hmastlock),
    .hsize                  (hsize),
    .htrans                 (htrans),
    .hwrite                 (hwrite),
    .hwdata                 (hwdata),
    .hrdata                 (hrdata),
    .hready                 (hready),
    .hresp                  (hresp),

    // Serial I/Os
    .fsin                   (fsin),
    .tdmin                  (tdmin),
    .fsout                  (fsout),
    .tdmout                 (tdmout)
);

sergen sergen (
    .sclk                   (gclk),
    .rstn                   (tbrstn),
    .enable                 (sergen_en),
    .sdata                  (tdmin),
    .sfs                    (fsin)
);

rectifier rxMon (
    .sclk                   (sclk),
    .rstn                   (tbrstn),
    .sdata                  (tdmin),
    .sfs                    (fsin),
    .pvalid                 (rxPvalid),
    .pdata                  (rxPdata)
);

scoreboard #(.ADDR(2), .WIDTH(256))
    rxScbd (
    .clk                    (sclk),
    .rstn                   (tbrstn),
    .push                   (rxPvalid),
    .din                    (rxPdata),
    .pop                    (rxChkExpPop),
    .dout                   (rxChkExpData),
    .level                  (),
    .empty                  (rxChkExpEmpty),
    .full                   ()
);

rectifier txMon (
    .sclk                   (sclk),
    .rstn                   (tbrstn),
    .sdata                  (tdmout),
    .sfs                    (fsout),
    .pvalid                 (txPvalid),
    .pdata                  (txPdata)
);

assign rxMonValid = ( passThru) ? txPvalid : regPvalid;
assign rxMonData  = ( passThru) ? txPdata  : regPdata;
assign txMonValid = !passThru && txPvalid;
assign txMonData  = txPdata;

checker rxCheck (
    .clk                    (sclk),
    .rstn                   (tbrstn),
    .expValid               (!rxChkExpEmpty),
    .expData                (rxChkExpData),
    .expPop                 (rxChkExpPop),
    .actValid               (rxMonValid),
    .actData                (rxMonData),
    .testPass               (rxTestPass)
);

//checker txCheck

`include "tasks.v"
//`include "stim.v"

endmodule


