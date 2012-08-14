/*
Author: Jeff Heckey (jheckey@gmail.com)
Copyright: 2011, all rights reserved

Module: tdm2p

Purpose: 
    Translate serial, 8-channel, 32-bit word TDM output from the ADC into 
    a 256-bit wide register.

Function:
    The TDM serial clock (sclk) is oversampled by the system clock (clk).
    The inputs clkPatt and clkMask are used to compare the 8 sclk samples
    to determine pos- and negedges. The serial data (tdmin) and the frame 
    sync (fs) are sampled on the rising edge of the sclk.

    Once the enable is released the deserializer will wait for the second 
    sclk rising edge after the rising edge of fs to start sampling data (as
    the specification states). 
    
    Serial data is sent in Channel 1 to 8, MSB to LSB. As such, bit 255 is 
    CH1 MSB, while bit 0 is CH8 LSB.

    Every data sample is loaded into a temporary register and then 
    transferred to the output register after the last data sample is loaded.
    The valid goes high for the clk cycle after the tranfer, though the data
    is available until the next valid.
*/

module tdm2p (
    input  wire         clk,        // system clock
    input  wire         rstn,       // async, active low reset

    input  wire         enable,     // enable de-serializer
    input  wire [7:0]   clkPatt,    // pattern for clock edge determination
    input  wire [7:0]   clkMask,    // mask for don't care bits in pattern
    
    input  wire         sclk,       // TDM serial clock
    input  wire         fs,         // TDM frame sync
    input  wire         tdmin,      // TDM data in

    output reg          valid,      // single-cycle (clk) valid for pdata
    output reg  [255:0] pdata       // parallel data for samples
);

reg             init;
reg  [7:0]      clkSamp;
reg             lastReg;
reg             lastFs;

reg  [7:0]      bit;
reg  [255:0]    tdata;
reg             next;

localparam POSEDGE = 1'b1, NEGEDGE = 1'b0;

// Generate signal to sample
wire posSamp    = (lastReg == NEGEDGE) && ((clkPatt && clkMask) == (clkSamp && clkMask));
wire negSamp    = (lastReg == POSEDGE) && ((~clkPatt && clkMask) == (clkSamp && clkMask));
wire sample     = !init && posSample;

// Sample sclk
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        init        <= 1'b1;
        clkSamp     <= 8'd0;
        lastReg     <= NEGEDGE;
        lastFs      <= 1'b0;
    end
    else begin
        init        <= (!enable) ? 1'b1             // re-init when disabled
                        // TDM will assert fs for 1 bittime before the next sample
                        : (posSamp && fs && !lastFs) ? 1'b0
                        : init;
        clkSamp     <= {clkSamp[6:0], sclk};        // collect next clock sample
        lastReg     <= (posSamp) ? POSEDGE          // track clock edges
                        : (negSamp) ? NEGEDGE 
                        : lastReg;
        lastFs      <= (posSamp) ? fs : lastFs;     // track fs samples
    end
end

// Shift data and load 
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        bit     <= 8'd255;
        tdata   <= 256'd0;
        pdata   <= 256'd0;
    end
    else begin
        if (!enable) begin
            bit     <= 8'd255;
            tdata   <= 256'd0;
        end
        else if (enable && sample) begin
            bit         <= bit - 8'd1;
            tdata[bit]  <= tdmin;
        end

        next    <= enable && sample && (bit == 8'd0);
        valid   <= next;
        pdata   <= (next) ? tdata : pdata;
    end
end

endmodule

