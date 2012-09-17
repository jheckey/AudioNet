module sergen (
    input  wire     sclk,
    input  wire     rstn,

    input  wire     enable,

    output reg      sdata,      // serial data
    output reg      sfs         // serial frame sync
);

reg [7:0] count;
integer rand;

always @(posedge sclk or negedge rstn)
begin
    if (!rstn) begin
        count   <= 8'd0;
        sdata   <= 1'b0;
        sfs     <= 1'b0;
    end
    else begin
        if (enable) begin
            count   <= count + 8'd1;
            sdata   <= {$random} % 2;
            sfs     <= (count == 0) ? 1'b1 : 1'b0;
        end
    end
end

endmodule

