
module rectifier (
    input  wire         sclk,
    input  wire         rstn,

    input  wire         sdata,
    input  wire         sfs,

    output reg          pvalid,
    output reg  [255:0] pdata
);

// Okay, so this needs to do rectifying and checking
reg [255:0] shiftreg;
reg         locked;

integer     bitcnt;

always @(posedge sclk or negedge rstn) begin
    if (!rstn) begin
        locked      <= 1'b0;
        shiftreg    <= 256'd0;

        pvalid      <= 1'b0;
        pdata       <= 256'd0;

        bitcnt      <= 0;
    end
    else begin
        // Shift in serial data
        if (sfs) begin
            // Lock on first sfs and stay locked
            locked      <= 1'b1;
            // Clear previous frame and get current data
            shiftreg    <= 256'd0;
        end
        else begin
            // Stay locked
            locked      <= locked;
            // shift in new data
            shiftreg    <= {shiftreg[254:0], sdata};
        end

        // Register output
        if (locked && sfs) begin
            // Valid for one cycle, latch current data from shift reg
            pvalid      <= 1'b1;
            pdata       <= {shiftreg[254:0], sdata};
        end
        else begin
            // Retain data for inspection
            pvalid      <= 1'b0;
            pdata       <= pdata;
        end

        // Count the bits that have been received
        if (!locked && sfs) begin
            bitcnt      <= 0;
        end
        else if (locked && sfs) begin
            if (bitcnt != 255)
                $display    ("ERROR: %t: %m: Frames was %d bits, not 255!", $time, bitcnt);

            bitcnt      <= 0;
        end
        else if (locked) begin
            bitcnt      <= bitcnt+1;
        end
    end
end

endmodule

