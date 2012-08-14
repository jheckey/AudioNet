module resetSync (
    input  wire     clk,
    input  wire     asyncRstn,
    output wire     syncRstn
);

parameter FLOPS = 2;

syncFlop #(.FLOPS(FLOPS)) sync (.clk(clk), .rstn(asyncRstn), .data(1'b1), .sync(syncRstn));

endmodule

