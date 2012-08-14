`timescale 1ns/1ns

module test;

reg sclk, srstn, enable;
wire clear;

always #1 sclk <= ~sclk;

always @(posedge clk)
    $display ("srstn = %d, enable = %d, clear = %d", srstn, enable, clear);

initial begin
    sclk = 0;
    srstn = 0;
    enable = 0;

#10 srstn = 1;
#10 enable = 1;
#10 $finish;
end

syncFlop #(.FLOPS(2)) syncClear (.clk(sclk), .rstn(srstn), .data(!enable), .sync(clear));

endmodule
