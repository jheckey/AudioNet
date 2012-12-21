/* TDM
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: tdm

Purpose: 
    Top-level of the system. Contains TDM to registers input and registers
    to TDM output.

Function:
    Simply, it takes 8 32-bit channels from a serial TDM stream, turns it
    into 256-bit parallel data presented to the registers, and takes
    256-bit parallel data from the registers and converts it to TDM output
    for 8 32-bit channels.

    All operations are controlled by the registers, so msot documentation is
    found there.
*/

module tdm (
    // Clocks and resets
    input  wire         clk,
    input  wire         rstn,
    input  wire         hclk,
    input  wire         hresetn,
    input  wire         sclk,

    // AHB bus interface
    input  wire         hsel,
    input  wire [31:0]  haddr,
    input  wire [2:0]   hburst,
    input  wire         hmastlock,
    input  wire [2:0]   hsize,
    input  wire [1:0]   htrans,
    input  wire         hwrite,
    input  wire [31:0]  hwdata,
    output wire [31:0]  hrdata,
    output wire         hready,
    output wire [1:0]   hresp,

    // Serial I/Os
    input  wire         fsin,
    input  wire         tdmin,
    output wire         fsout,
    output wire         tdmout
);

localparam FLOPS = 2;

wire [15:0]     p2tdmRetrans;
wire [15:0]     p2tdmDropped;
wire [255:0]    muxPdata;
wire            srstn;
wire            muxPdataValid;

/*AUTOWIRE*/
// Beginning of automatic wires (for undeclared instantiated-module outputs)
wire [9:0]              addr;                   // From ahbSlv of ahbSlv.v
wire [31:0]             bal;                    // From regs of regs.v
wire                    fsOut;                  // From p2tdm of p2tdm.v
wire [63:0]             gain;                   // From regs of regs.v
wire                    p2tdmDroppedIncr;       // From regs of regs.v, ...
wire                    p2tdmEnable;            // From regs of regs.v
wire [255:0]            p2tdmPdata;             // From regs of regs.v
wire                    p2tdmRetransIncr;       // From regs of regs.v, ...
wire                    p2tdmValid;             // From regs of regs.v
wire [255:0]            pdata;                  // From gainBal of gainBal.v
wire [31:0]             rdata;                  // From regs of regs.v
wire                    ready;                  // From regs of regs.v
wire                    sel;                    // From regs of regs.v
wire [7:0]              tdm2pClkMask;           // From regs of regs.v
wire [7:0]              tdm2pClkPatt;           // From regs of regs.v
wire                    tdm2pEnable;            // From regs of regs.v
wire [255:0]            tdm2pPdata;             // From tdm2p of tdm2p.v
wire                    tdm2pValid;             // From tdm2p of tdm2p.v
wire                    tdm2pSample;            // From tdm2p of tdm2p.v
wire                    tdmOut;                 // From p2tdm of p2tdm.v
wire                    val;                    // From ahbSlv of ahbSlv.v
wire                    valid;                  // From gainBal of gainBal.v
wire [31:0]             wdata;                  // From ahbSlv of ahbSlv.v
wire                    write;                  // From ahbSlv of ahbSlv.v
// End of automatics
/*AUTOREGS*/

// Clock crossing reset
resetSync #(
    .FLOPS(FLOPS)
) rstn2srstn (
    .clk        (sclk),
    .asyncRstn  (rstn),
    .syncRstn   (srstn)
);

// AHBSLV
ahbSlv ahbSlv (/*AUTOINST*/
               // Outputs
               .hrdata                  (hrdata[31:0]),
               .hready                  (hready),
               .hresp                   (hresp[1:0]),
               .val                     (val),
               .addr                    (addr[9:0]),
               .write                   (write),
               .wdata                   (wdata[31:0]),
               // Inputs
               .hclk                    (hclk),
               .hresetn                 (hresetn),
               .hsel                    (hsel),
               .haddr                   (haddr[31:0]),
               .hburst                  (hburst[2:0]),
               .hmastlock               (hmastlock),
               .hsize                   (hsize[2:0]),
               .htrans                  (htrans[1:0]),
               .hwdata                  (hwdata[31:0]),
               .hwrite                  (hwrite),
               .rdata                   (rdata[31:0]),
               .ready                   (ready));

// REGS
regs regs (/*AUTOINST*/
           // Outputs
           .rdata                       (rdata[31:0]),
           .ready                       (ready),
           .tdm2pEnable                 (tdm2pEnable),
           .tdm2pClkMask                (tdm2pClkMask[7:0]),
           .tdm2pClkPatt                (tdm2pClkPatt[7:0]),
           .p2tdmEnable                 (p2tdmEnable),
           .p2tdmRetransIncr            (p2tdmRetransIncr),
           .p2tdmDroppedIncr            (p2tdmDroppedIncr),
           .p2tdmPdata                  (p2tdmPdata[255:0]),
           .p2tdmValid                  (p2tdmValid),
           .gain                        (gain[63:0]),
           .bal                         (bal[31:0]),
           .sel                         (sel),
           // Inputs
           .clk                         (clk),
           .rstn                        (rstn),
           .val                         (val),
           .addr                        (addr[9:0]),
           .write                       (write),
           .wdata                       (wdata[31:0]),
           .tdm2pSample                 (tdm2pSample),
           .tdm2pValid                  (tdm2pValid),
           .tdm2pPdata                  (tdm2pPdata[255:0]),
           .p2tdmRetrans                (p2tdmRetrans[15:0]),
           .p2tdmDropped                (p2tdmDropped[15:0]));

// TDM2P
/* tdm2p AUTO_TEMPLATE (
        .enable         (tdm2pEnable),
        .clk\(.+\)      (tdm2pClk\1[]),
        .sample         (tdm2pSample),
        .valid          (tdm2pValid),
        .pdata          (tdm2pPdata[]),
        .fs             (fsin),
   );
*/
tdm2p tdm2p (/*AUTOINST*/
             // Outputs
             .sample                    (tdm2pSample),           // Templated
             .valid                     (tdm2pValid),            // Templated
             .pdata                     (tdm2pPdata[255:0]),     // Templated
             // Inputs
             .clk                       (clk),
             .rstn                      (rstn),
             .enable                    (tdm2pEnable),           // Templated
             .clkPatt                   (tdm2pClkPatt[7:0]),     // Templated
             .clkMask                   (tdm2pClkMask[7:0]),     // Templated
             .sclk                      (sclk),
             .fs                        (fsin),
             .tdmin                     (tdmin));

// TDM Pass-thru MUX
tdmMux tdmMux (
           .sel                         (sel),
           .tdmPdataValid0              (p2tdmValid),
           .tdmPdata0                   (p2tdmPdata[255:0]),
           .tdmPdataValid1              (tdm2pValid),
           .tdmPdata1                   (tdm2pPdata[255:0]),
           .tdmPdataValidX              (muxPdataValid),
           .tdmPdataX                   (muxPdata[255:0])
);

// DSP_DUMMY / GAIN/BAL
/* gainBal AUTO_TEMPLATE (
        .din_val        (muxPdataValid),
        .din            (muxPdata[]),
        .dout_val       (valid),
        .dout           (pdata[]),
   );
*/
gainBal gainBal (/*AUTOINST*/
                 // Outputs
                 .dout_val              (valid),                 // Templated
                 .dout                  (pdata[255:0]),          // Templated
                 // Inputs
                 .clk                   (clk),
                 .rstn                  (rstn),
                 .din_val               (muxPdataValid),         // Templated
                 .din                   (muxPdata[255:0]),       // Templated
                 .gain                  (gain[63:0]),
                 .bal                   (bal[31:0]));

// P2TDM
/* p2tdm AUTO_TEMPLATE (
        .enable         (p2tdmEnable),
        .clk\(.+\)      (p2tdmClk\1[]),
        .fs             (fsOut),
        .tdmout         (tdmOut),
        .retransIncr    (p2tdmRetransIncr),
        .droppedIncr    (p2tdmDroppedIncr),
   );
*/
p2tdm p2tdm (/*AUTOINST*/
             // Outputs
             .fs                        (fsOut),
             .tdmout                    (tdmOut),
             .retransIncr               (p2tdmRetransIncr),      // Templated
             .droppedIncr               (p2tdmDroppedIncr),      // Templated
             // Inputs
             .clk                       (clk),
             .rstn                      (rstn),
             .enable                    (p2tdmEnable),           // Templated
             // Bypassing gainBal for debugging
             //.valid                     (valid),
             //.pdata                     (pdata[255:0]),
             .valid                 (muxPdataValid),         // Templated
             .pdata                 (muxPdata[255:0]),       // Templated
             .sclk                      (sclk),
             .srstn                     (srstn));

// SYNCFLOPS to PADS
syncFlop #(
    .FLOPS(FLOPS)
) fs2sclk (
    .clk        (sclk),
    .rstn       (srstn),
    .data       (fsOut),
    .sync       (fsout)
);

syncFlop #(
    .FLOPS(FLOPS)
) tdm2sclk (
    .clk        (sclk),
    .rstn       (srstn),
    .data       (tdmOut),
    .sync       (tdmout)
);

// PADS

endmodule

