/* Top level test
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

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
        * tbconfig - configuration script loader (not implemented)
*/

`timescale 1ns/1ns

module tb;
// Clocks and resets
reg          clk;       // system clock
reg          rstn;      // system reset
reg          hclk;      // AHB clock
reg          hresetn;   // AHB reset
reg          sclk;      // serial/TDM clock
reg          gclk;      // generator clock (may contain jitter)
reg          tbrstn;    // testbench reset


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
integer             dump;
reg  [8*256-1:0]    configFile;
wire                cfgRdy;
reg                 sergenEn, serjitEn, regMonEn; // tb control signals
wire                sergenEnable, serjitEnable, regMonEnable; // config signals
wire                p2tdm, tdm2p;
wire [7:0]          tdmMask, tdmPatt;
wire                passThru;
wire [31:0]         regPollDelay;
wire                directData, ddataEn, ddata;
wire                rxTestPass, txTestPass;
wire                rxPvalid, regPvalid, txPvalid;
wire [255:0]        rxPdata, regPdata, txPdata;
wire                rxChkExpEmpty, rxChkExpPop;
wire                txChkExpEmpty, txChkExpPop;
wire [255:0]        rxChkExpData, txChkExpData;
wire                rxMonValid, txMonValid;
wire [255:0]        rxMonData, txMonData;

/* Dump controls */
initial begin
    if (! $value$plusargs("dump=%d", dump)) begin
        $display("%t: Opening dumpfile", $time);
        $dumpfile("/tmp/all.lxt");
        $dumpvars(0,tb);
    end
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

    hsel      = 1'b0;
    haddr     = 32'd0;
    hburst    = 3'd0;
    hmastlock = 1'b0;
    hsize     = 3'd0;
    htrans    = 2'd0;
    hwrite    = 1'b0;
    hwdata    = 32'd0;

    sergenEn  = 1'b0;
    regMonEn  = 1'b0;

    if (! $value$plusargs("cfg=%s", configFile)) begin
        $display ("Please specify a config file: +cfg=<file>");
        $finish;
    end

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
    write_reg(32'h0000_0300, {31'd0,passThru});
    if (passThru)
        $display("INIT: bypass enabled");

    // Enable p2tdm
    write_reg(32'h0000_0100, {p2tdm,32'd0});
    if (p2tdm)
        $display("INIT: p2tdm enabled");

    // Enable tdm2p, look for the pattern tdmPatt
    write_reg(32'h0000_0000, {tdm2p,15'd0,tdmMask,tdmPatt});
    if (tdm2p)
        $display("INIT: tdm2p enabled, sync pattern 0x%02h, mask 0x%02h", tdmPatt, tdmMask);

    if (directData)
        $display("INIT: serial data enabled, specified data pattern used");

    if (ddataEn && directData)
        $display("INIT: serial data enabled, using custom data from %-s", configFile);
    else if (ddataEn && !directData)
        $display("INIT: random serial data enabled");

    // Start testing
    #10
    $display("%t: Starting serial generation...", $time);
    sergenEn = sergenEnable;
    regMonEn = regMonEnable;

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

tbconfig tbconfig (
    .configFile(configFile),
    .p2tdm(p2tdm),
    .tdm2p(tdm2p),
    .tdmPatt(tdmPatt),
    .tdmMask(tdmMask),
    .passThru(passThru),
    .sergenEnable(sergenEnable),
    .serjitEnable(serjitEnable),
    .regMonEnable(regMonEnable),
    .regPollDelay(regPollDelay),
    .directData(directData),
    .cfgRdy(cfgRdy),
    .sclk(gclk),
    .ddataEn(ddataEn),
    .ddata(ddata)
);

sergen sergen (
    .sclk                   (gclk),
    .rstn                   (tbrstn),
    .enable                 (sergenEn),
    .directData             (directData),
    .ddata                  (ddata),
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

regmon regMon (
    .rclk                   (hclk),
    .sclk                   (sclk),
    .rstn                   (tbrstn),
    .enable                 (regMonEn),
    .pollingDelay           (regPollDelay),
    .pValid                 (regPvalid),
    .pData                  (regPdata)
);

`include "tasks.v"
//`include "stim.v"

endmodule


