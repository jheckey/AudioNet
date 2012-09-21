module regs (
    input  wire             clk,
    input  wire             rstn,

    input  wire             val,
    input  wire [9:0]       addr,
    input  wire             write,
    input  wire [31:0]      wdata,
    output reg  [31:0]      rdata,
    output reg              ready,

    output reg              tdm2pEnable,
    output reg  [7:0]       tdm2pClkMask,
    output reg  [7:0]       tdm2pClkPatt,
    input  wire             tdm2pValid,
    input  wire [255:0]     tdm2pPdata,

    output reg              p2tdmEnable,
    output reg  [15:0]      p2tdmRetrans,
    output reg  [15:0]      p2tdmDropped,
    input  wire             p2tdmRetransIncr,
    input  wire             p2tdmDroppedIncr,
    output reg              p2tdmValid,
    output reg  [255:0]     p2tdmPdata,

    output reg  [63:0]      gain,
    output reg  [31:0]      bal,

    output reg              sel
);

integer i;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        // TDM2P signals
        tdm2pEnable     <= 1'b0;
        tdm2pClkMask    <= 8'd0;
        tdm2pClkPatt    <= 8'd0;

        // P2TDM signals
        p2tdmEnable     <= 1'b0;
        p2tdmRetrans    <= 16'd0;
        p2tdmDropped    <= 16'd0;
        p2tdmValid      <= 1'b0;
        p2tdmPdata      <= 256'd0;

        gain[63:0]      <= 64'd0;
        bal[31:0]       <= 32'd0;

        // TDM MUX signals
        sel             <= 1'b0;
    end
    else begin

        if (val && write) begin
            ready   <= 1'b1;
            rdata   <= wdata;

            case (addr)

            // TDM2P
            10'h000:
            begin
                tdm2pEnable     <= wdata[31];
                tdm2pClkMask    <= wdata[15:8];
                tdm2pClkPatt    <= wdata[7:0];
            end

            // P2TDM
            10'h100:
            begin
                p2tdmEnable     <= wdata[31];
            end

            10'h104:
            begin
                p2tdmRetrans    <= wdata[31:16];
                p2tdmDropped    <= wdata[15:0];
            end

            // GAIN and BAL
            10'h200:
            begin
                bal[7:0]        <= wdata[23:16];
                gain[15:8]      <= wdata[15:8];
                gain[7:0]       <= wdata[7:0];
            end

            10'h204:
            begin
                bal[15:8]       <= wdata[23:16];
                gain[31:24]     <= wdata[15:8];
                gain[23:16]     <= wdata[7:0];
            end

            10'h208:
            begin
                bal[23:16]      <= wdata[23:16];
                gain[47:40]     <= wdata[15:8];
                gain[39:32]     <= wdata[7:0];
            end

            10'h20C:
            begin
                bal[23:16]      <= wdata[23:16];
                gain[63:56]     <= wdata[15:8];
                gain[55:48]     <= wdata[7:0];
            end

            // TDM MUX Select
            10'h300:
            begin
                sel             <= wdata[0];
            end

            default : ; // do nothing
            endcase
        end
        if (val) begin
            ready   <= 1'b1;

            case (addr)

            // TDM2P
            10'h000: rdata  <= {tdm2pEnable, 15'd0, tdm2pClkMask, tdm2pClkPatt};
            10'h010: rdata  <= tdm2pPdata[31:0];
            10'h014: rdata  <= tdm2pPdata[63:32];
            10'h018: rdata  <= tdm2pPdata[95:64];
            10'h01C: rdata  <= tdm2pPdata[127:96];
            10'h020: rdata  <= tdm2pPdata[159:128];
            10'h024: rdata  <= tdm2pPdata[191:160];
            10'h028: rdata  <= tdm2pPdata[223:192];
            10'h02C: rdata  <= tdm2pPdata[255:224];

            // P2TDM
            10'h100: rdata  <= {p2tdmEnable, 31'd0};
            10'h104: rdata  <= {p2tdmRetrans, p2tdmDropped};
            10'h110: rdata  <= tdm2pPdata[31:0];
            10'h114: rdata  <= tdm2pPdata[63:32];
            10'h118: rdata  <= tdm2pPdata[95:64];
            10'h11C: rdata  <= tdm2pPdata[127:96];
            10'h120: rdata  <= tdm2pPdata[159:128];
            10'h124: rdata  <= tdm2pPdata[191:160];
            10'h128: rdata  <= tdm2pPdata[223:192];
            10'h12C: rdata  <= tdm2pPdata[255:224];

            // GAIN and BAL
            10'h200: rdata  <= {8'd0, bal[7:0]  , gain[15:0 ]};
            10'h204: rdata  <= {8'd0, bal[15:7] , gain[31:16]};
            10'h208: rdata  <= {8'd0, bal[23:16], gain[47:32]};
            10'h20C: rdata  <= {8'd0, bal[31:24], gain[63:48]};

            // TDM MUX Select
            10'h300: rdata  <= {31'd0, sel};

            default : rdata <= 32'hbad_ace55;
            endcase
        end
        else begin
            ready   <= 1'b0;
            rdata   <= 32'd0;

            p2tdmRetrans    <= (p2tdmRetransIncr) ? p2tdmRetrans + 16'd1 : p2tdmRetrans;
            p2tdmDropped    <= (p2tdmDroppedIncr) ? p2tdmDropped + 16'd1 : p2tdmDropped;
        end
    end
end

endmodule

