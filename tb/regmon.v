/* register monitor
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: regmon

Purpose: 
    Monitors the registers for valid output and errors for data checking 
    and status purposes

Function:
    A task, pollReg, polls for new data in the registers and copies it to
    the clock crossing data register. It also signals the handshake logic
    that there is valid data.

    Regmon uses a three-part handshake for clock-crossing from the AHB 
    clock to the serial clock that the checkers use. When pollReg indicates
    that new data is ready, the regValid will assert. At this point, the serial
    clock side will copy the data into that clock domain and signal that it
    has been received by asserting regAck. Once the regAck has been seen in 
    the AHB clock domain, regValid is deasserted.

    This mechanism, as coded, will most likely only work in simualtion,
    do not use it as a template for real clock crossing.

    THIS MODULE IS NOT SYNTHESIZABLE. It is just for verification.
*/

module regmon (
    input  wire         rclk,
    input  wire         sclk,
    input  wire         rstn,

    input  wire         enable,
    input  wire [31:0]  pollingDelay,

    output reg          pValid,
    output reg  [255:0] pData
);

reg         dataRead, regValid, regAck;
reg [255:0] regData;

task pollReg;
    reg [31:0]  regRead;
    integer     i;
begin
    dataRead = 1'b0;

    while (1) begin
        wait (enable);

        // Read data if valid is set
        read_reg(32'h0000_0004, regRead);
        if (regRead[0] == 1'b1) begin
            for (i=0; i<8; i=i+1) begin
                read_reg( (32'h0000_0010 + i*4), regData[i +: 32] );
            end
            write_reg (32'h0000_0004, 32'd0);   // clear valid
            dataRead = 1'b1;
            wait_hclks(1);
            dataRead = 1'b0;
        end

        wait_hclks(pollingDelay);
    end
end
endtask

initial begin
    pollReg;
end

always @(posedge rclk or negedge rstn) begin
    if (!rstn) begin
        regValid <= 1'b0;
    end
    else begin
        if (dataRead && regValid) begin
            $display ("ERROR: %t: regMon missed a packet", $time);
        end

        regValid <= (regValid && regAck) ? 1'b0 : dataRead || regValid;
    end
end

always @(posedge sclk or negedge rstn) begin
    if (!rstn) begin
        regAck  <= 1'b0;
        pValid  <= 1'b0;
        pData   <= 256'd0;
    end
    else begin
        if (regValid) begin
            regAck  <= 1'b1;
            pValid  <= regValid && !regAck; // pulse once
            pData   <= regData;
        end
        else if (!regValid) begin
            regAck  <= 1'b0;
            pValid  <= 1'b0;
            pData   <= pData;
        end
    end
end

endmodule

