
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
reg          fsin;
reg          tdmin;
wire         fsout;
wire         tdmout;

initial begin
    clk     = 1'b0;
    sclk    = 1'b0;
    hclk    = 1'b0;
    rstn    = 1'b0;
    hresetn = 1'b0;

    #20
    rstn    = 1'b1;
    hresetn = 1'b1;
end

always #1   clk  <= ~clk;   // 100  Mhz
always #1   hclk <= ~hclk;  // 100  Mhz
always #8   sclk <= ~sclk;  // 12.5 Mhz


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

`include "tasks.v"
//`include "stim.v"

endmodule


