module gcCntr8 (
    input  wire         clk,
    input  wire         rstn,

    input  wire         clear,
    output reg  [7:0]   cntr,
    output wire [7:0]   gc
);

assign gc = {cntr[7], ^cntr[7:6], ^cntr[6:5], ^cntr[5:4],
            ^cntr[4:3], ^cntr[3:2], ^cntr[2:1], ^cntr[1:0]};

always @(posedge clk or negedge rstn) begin
    if (rstn)
        cntr    <= 8'd0;
    else
        cntr    <= (clear) ? 8'd0 : cntr + 8'd1;
end

endmodule

