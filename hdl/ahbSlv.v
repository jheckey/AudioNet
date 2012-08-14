module ahbSlv (
    input  wire             hclk,
    input  wire             hresetn,
    input  wire             hsel,
    input  wire [31:0]      haddr,
    input  wire [2:0]       hburst,
    input  wire             hmastlock,
    input  wire [2:0]       hsize,
    input  wire [1:0]       htrans,
    input  wire [31:0]      hwdata,
    input  wire             hwrite,
    output wire [31:0]      hrdata,
    output wire             hready,
    output wire [1:0]       hresp,

    output reg              val,
    output reg  [9:0]       addr,
    output reg              write,
    output reg  [31:0]      wdata,
    input  wire [31:0]      rdata,
    input  wire             ready
);

reg  [9:0]     burstAddr;

localparam [1:0] IDLE   = 2'b00,
                 BUSY   = 2'b01,
                 NONSEQ = 2'b10,
                 SEQ    = 2'b11;

localparam [2:0] SINGLE = 3'b000,
                 INCR   = 3'b001,
                 WRAP4  = 3'b010,
                 INCR4  = 3'b011,
                 WRAP8  = 3'b100,
                 INCR8  = 3'b101,
                 WRAP16 = 3'b110,
                 INCR16 = 3'b111;

assign hrdata  = (ready) ? rdata : 32'd0;
assign hready  = ready;
assign hresp   = 2'b00;   // ERROR, RETRY, and SPLIT are not supported

always @(posedge hclk or negedge hresetn) begin
    if (!hresetn) begin
        // Reg control
        val     <= 1'b0;
        addr    <= 10'd0;
        write   <= 1'b0;
        wdata   <= 32'd0;
    end
    else begin
        if (hsel) begin
            case (htrans)
            IDLE: begin // Inactive - wait for next input
                val     <= 1'b0;
                addr    <= 12'd0;
                write   <= 1'b0;
                wdata   <= 32'd0;
            end

            BUSY: begin // Not finished, but not ready to accept data
                val     <= 1'b0;
                addr    <= addr;
                write   <= write;
                wdata   <= wdata;
            end

            NONSEQ: begin // Start of new transfer
                val     <= 1'b1;
                addr    <= haddr[9:0];
                write   <= hwrite;
                wdata   <= (hwrite) ? hwdata : 32'd0;
            end

            SEQ: begin  // Continuation of previous transfer
                val     <= 1'b1;
                addr    <= burstAddr;
                write   <= hwrite;
                wdata   <= (hwrite) ? hwdata : 32'd0;
            end

            default : ; // Fully described
            endcase
        end
        else begin
            val     <= 1'b0;
        end
    end
end

always @(*) begin
    burstAddr = addr;   // no latches

    if (hsel) begin
        case (hburst)
        SINGLE: burstAddr = addr;
        INCR:   burstAddr = addr + 10'd4;
        WRAP4:  burstAddr = {addr[9:4], addr[3:0] + 10'd4};
        INCR4:  burstAddr = addr + 10'd4;
        WRAP8:  burstAddr = {addr[9:5], addr[4:0] + 10'd4};
        INCR8:  burstAddr = addr + 10'd4;
        WRAP16: burstAddr = {addr[9:6], addr[5:0] + 10'd4};
        INCR16: burstAddr = addr + 10'd4;
        default : ;     // Fully described
        endcase
    end
end

endmodule

