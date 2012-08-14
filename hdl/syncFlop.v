module syncFlop (
    input  wire     clk,
    input  wire     rstn,
    input  wire     data,
    output wire     sync
);

parameter FLOPS = 2;

reg [FLOPS-1:0] stage;
integer i;

assign sync = stage[FLOPS-1];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        for (i=0; i<FLOPS; i=i+1) begin
            stage[i]   <= 1'b0;
        end
    end
    else begin
        stage[0]    <= data;

        for (i=1; i<FLOPS; i=i+1) begin
            stage[i]    <= stage[i-1];
        end
    end
end

endmodule

