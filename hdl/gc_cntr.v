module gc_cntr (
    input  wire         clk,
    input  wire         rstn,

    input  wire         clear,
    output reg  [7:0]   cntr,
    output reg  [7:0]   gc
);

parameter WIDTH = 8;

integer i;
always @(*) begin
    gc[WIDTH-1] = cntr[WIDTH-1];

    for (i = 0; i < WIDTH; i = i+1)
        gc[i] = ^cntr[i+1:i];
end

always @(posedge clk or negedge rstn) begin
    if (rstn)
        cntr <= {WIDTH-1{1'b0}};
    else
        cntr <= (clr) ? {WIDTH-1{1'b0}} : cntr + 8'd1;
end

endmodule

