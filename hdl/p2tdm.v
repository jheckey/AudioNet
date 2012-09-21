/*
Author: Jeff Heckey (jheckey@gmail.com)
Copyright: 2011, all rights reserved

Module: p2tdm

Purpose:
    Translate parallel data from a 256-bit wide register into serial, 
    8-channel, 32-bit word TDM format output to the DAC

Function:
    This module is in two clock domains, the system clock and the serial 
    clock.

    The serial clock domain is used to transmit the serial data as it is 
    received from the system domain. The serial domain also maintains a 
    counter to select which bit to transmit. The counter is grey-coded
    and sent to the system clock domain across sync flops.


Registers:
    System clock domain:
    * stage[255:0]  - this always accepts incoming valid data
    * stageV        - this indicates if the data in stage is valid or acked
                      It is used to determine if we are retransmitting or 
                      dropping any frames
    * tdata[255:0]  - this will load valid data from stage
    * tdataV        - indicates if the data in tdata is valid 
                      and transmission should begin
    * pTdmout       - the serial bit to send; this will be sent to the
                      serial clock domain
    * pFs           - the frame start bit to send; this will be sent to the
                      serial clock domain

    Serial clock domain:
    * gc            - The output of an 8-bit grey coded counter used to 
                      select the bit to transmit
    * lastFsGc      - The last count (in grey code) when an FS was seen
    * bitSlip       - indicates that a bit slip was seen (FS seen on a 
                      different GC count than last time)

Operational notes:
    Once the first frame is transmitted, a single bitSlip should be seen;
    this indicates that the grey-code changed for the first the FS. If 
    additional bitSlips are seen, this indicates a poor design or 
    significant delay in the sync flops.
*/

module p2tdm (
    input  wire         clk,            // system clock
    input  wire         rstn,           // async, active low reset

    input  wire         enable,         // enable de-serializer
    input  wire         valid,          // valid for pdata
    input  wire [255:0] pdata,          // parallel data for samples
    
    input  wire         sclk,           // TDM serial clock
    input  wire         srstn,          // TDM clk synced reset
    output wire         fs,             // TDM frame sync
    output wire         tdmout,         // TDM data out

    output reg          bitSlipIncr,    // count a bitslip
    output reg          retransIncr,    // count a retransmitted frame
    output reg          droppedIncr     // count a dropped frame
);

reg [255:0] stage, tdata;
reg         stageV, tdataV, pFs, pTdmout;
reg         lastBitSlipDetect, lastCnt0;
reg [7:0]   fsGc;

wire        sclear;
wire        bitSlip, bitSlipDetect;
wire [7:0]  gc;
wire [7:0]  sgc;
wire [7:0]  cnt;

wire cnt0   = (cnt == 8'd0);
wire ack    = (stageV && !tdataV) || (cnt0 && !lastCnt0);    // edge-detect
wire clear  = !(stageV || tdataV);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        stageV  <= 1'b0;
        stage   <= 256'd0;
        tdataV  <= 1'b0;
        tdata   <= 256'd0;
        pFs     <= 1'b0;
        pTdmout <= 1'b0;

        lastCnt0            <= 1'b0;    // Counter intializes to 0, reset hi
        lastBitSlipDetect   <= 1'b0;

        bitSlipIncr <= 1'b0;
        retransIncr <= 1'b0;
        droppedIncr <= 1'b0;
    end
    else begin
        if (!enable) begin
            // This acts as reset, without resetting the counters
            stageV  <= 1'b0;
            stage   <= 256'd0;
            tdataV  <= 1'b0;
            tdata   <= 256'd0;
            pFs     <= 1'b0;
            pTdmout <= 1'b0;

            lastCnt0            <= 1'b0;
            lastBitSlipDetect   <= 1'b0;

            bitSlipIncr <= 1'b0;
            retransIncr <= 1'b0;
            droppedIncr <= 1'b0;
        end
        else begin
            if (valid) begin
                // Always accept data on valid
                stage   <= pdata;
                stageV  <= 1'b1;
            end
            else if (!valid && cnt0) begin
                // clear valid when staged data is taken
                stageV  <= 1'b0;
            end

            if (ack && stageV) begin
                // Accept new data
                tdata   <= stage;
                tdataV  <= stageV;
            end

            if (ack && (stageV || tdataV)) begin
                pTdmout <= stage[0];    
                // bypass tdata to avoid bit shifting
                // cnt == 0, but that bit may not 
                // be in tdata yet
            end
            else begin
                pTdmout <= tdata[cnt];
            end

            pFs <= tdataV && cnt0;

            // Edge detection
            lastCnt0            <= cnt0;
            lastBitSlipDetect   <= bitSlipDetect;

            bitSlipIncr <= bitSlipDetect && !lastBitSlipDetect; // edge-detect
            retransIncr <= ack && !stageV;  // count rolled without new frame
            droppedIncr <= valid && stageV; // new frame added with one not sent
        end // enabled
    end // out of reset
end

/********************
  Generate and synchronize counter
********************/
syncFlop #(.FLOPS(2), .RESET(1'b1)) syncClear (.clk(sclk), .rstn(srstn), .data(clear), .sync(sclear));

gcCntr8 gcCntr (.clk(sclk), .rstn(rstn), .load(sclear), .updn(0), .num(8'd1), .cntr(), .gc(gc));

genvar i;
generate
    for (i=0; i<8; i=i+1) begin : GEN_SYNC
        syncFlop #(.FLOPS(2)) gcSync (.clk(clk), .rstn(rstn), .data(gc[i]), .sync(sgc[i]));
    end
endgenerate

gc2bin8 gc2b (.gc(sgc), .bin(cnt));

always @(posedge sclk or negedge srstn) begin
    if (!srstn)
        fsGc    <= 8'd0;
    else
        fsGc    <= (fs) ? gc : fsGc;
end

// if the FS is seen and the flopped count isn't the same as the current, we slipped a bit
assign bitSlip = (fs) ? (gc != fsGc) : 1'b0;

syncFlop #(.FLOPS(2)) bsSync (.clk(clk), .rstn(rstn), .data(bitSlip), .sync(bitSlipDetect));

/****************
  Retime output
  -- This should be a DLL or PLL
****************/
syncFlop syncFs (.clk(sclk), .rstn(srstn), .data(pFs), .sync(fs));
syncFlop syncTdm (.clk(sclk), .rstn(srstn), .data(pTdmout), .sync(tdmout));


endmodule

/*
            case ({valid,stageV,tdataV,cnt0})

            4'b0010:
            // vstn
            begin
                stageV  <= stageV;
                stage   <= stage;
                tdataVn <= tdataVn;
                tdata   <= tdata;
                pFs     <= cnt0;
                pTdmout <= tdata[cnt];

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b0011:
            // vstn
            begin
                stageV  <= stageV;
                stage   <= stage;
                tdataVn <= tdataVn;
                tdata   <= tdata;
                pFs     <= cnt0;
                pTdmout <= tdata[cnt];

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b1;
                droppedIncr <= 1'b0;
            end

            4'b0100:
            // vstn
            begin
                stageV  <= 1'b0;
                stage   <= stage;
                tdataVn <= !stageV;
                tdata   <= stage;
                pFs     <= cnt0;
                pTdmout <= tdata[cnt];

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b0101:
            // vstn
            begin
                stageV  <= 1'b0;
                stage   <= stage;
                tdataVn <= !stageV;
                tdata   <= tdata;
                pFs     <= cnt0;
                pTdmout <= tdata[cnt];

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b0110:
            // vstn
            begin
                stageV  <= 1'b0;
                stage   <= 256'd0;
                tdataVn <= 1'b1;
                tdata   <= 256'd0;
                pFs     <= 1'b0;
                pTdmout <= 1'b0;

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b0111:
            // vstn
            begin
                stageV  <= 1'b0;
                stage   <= 256'd0;
                tdataVn <= 1'b1;
                tdata   <= 256'd0;
                pFs     <= 1'b0;
                pTdmout <= 1'b0;

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b1000:
            // vstn
            begin
                stageV  <= 1'b1;
                stage   <= pdata;
                tdataVn <= 1'b1;
                tdata   <= 256'd0;
                pFs     <= 1'b0;
                pTdmout <= 1'b0;

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b1001:
            // vstn
            begin
                stageV  <= 1'b0;
                stage   <= 256'd0;
                tdataVn <= 1'b1;
                tdata   <= 256'd0;
                pFs     <= 1'b0;
                pTdmout <= 1'b0;

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b1010:
            // vstn
            begin
                stageV  <= 1'b0;
                stage   <= 256'd0;
                tdataVn <= 1'b1;
                tdata   <= 256'd0;
                pFs     <= 1'b0;
                pTdmout <= 1'b0;

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b1011:
            // vstn
            begin
                stageV  <= 1'b0;
                stage   <= 256'd0;
                tdataVn <= 1'b1;
                tdata   <= 256'd0;
                pFs     <= 1'b0;
                pTdmout <= 1'b0;

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b1100:
            // vstn
            begin
                stageV  <= 1'b0;
                stage   <= 256'd0;
                tdataVn <= 1'b1;
                tdata   <= 256'd0;
                pFs     <= 1'b0;
                pTdmout <= 1'b0;

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b1101:
            // vstn
            begin
                stageV  <= 1'b0;
                stage   <= 256'd0;
                tdataVn <= 1'b1;
                tdata   <= 256'd0;
                pFs     <= 1'b0;
                pTdmout <= 1'b0;

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b1110:
            // vstn
            begin
                stageV  <= 1'b0;
                stage   <= 256'd0;
                tdataVn <= 1'b1;
                tdata   <= 256'd0;
                pFs     <= 1'b0;
                pTdmout <= 1'b0;

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b1111:
            // vstn
            begin
                stageV  <= 1'b0;
                stage   <= 256'd0;
                tdataVn <= 1'b1;
                tdata   <= 256'd0;
                pFs     <= 1'b0;
                pTdmout <= 1'b0;

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            4'b0000:
            4'b0001:
            default:
            begin
                // Maintain current state
                stageV  <= stageV;
                stage   <= stage;
                tdataVn <= tdataVn;
                tdata   <= tdata;
                pFs     <= pFs;
                pTdmout <= pTdmout;

                bitSlipIncr <= 1'b0;
                retransIncr <= 1'b0;
                droppedIncr <= 1'b0;
            end

            endcase
*/
