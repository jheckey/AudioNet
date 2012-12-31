/* testbench configuration script loading
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: tbconfig

Purpose: 
    Loads a configuration file and sets the appropriate registers

Function:
    Reads in the given config file name, reads the contents and sets the 
    correct values in the registers.

    Uses 1 for enable, 0 for disable, and integers where needed. If a 
    command is not used, the default is used.

    Currently supports the following commands:
        passThru [en]       - control passThru mode (default disabled)
        sergen [en]         - control random data generator (default enabled)
        serjit [en]         - control input jitter control (default disabled)
        regMonEnable [en]   - enable regmon (default is enabled)
        regPollDelay [int]  - number of cycles to wait between polling 
                              registers (default 1000)
        directData          - a directed data pattern is given; all 
                              remaining lines in the file should be 32-bit, 
                              single hex numbers (little endian) that is 
                              the serial data to use

    THIS MODULE IS NOT SYNTHESIZABLE. It is just for verification.
*/

module tbconfig (
    input  wire [8*256-1:0] configFile,

    output reg              p2tdm,
    output reg              tdm2p,
    output reg  [7:0]       tdmPatt,
    output reg  [7:0]       tdmMask,
    output reg              passThru,
    output reg              sergenEnable,
    output reg              serjitEnable,
    output reg              regMonEnable,
    output reg  [31:0]      regPollDelay,
    output reg              directData,

    output reg              cfgRdy,

    input  wire             sclk,
    input  wire             ddataEn,
    output reg              ddata
);

integer file, i, r, error;
reg [16*8:1] line;
reg [31:0] data;

initial begin
    error = 0;
    ddata = 1'b0;
    cfgRdy = 1'b0;
    p2tdm = 1'b1;
    tdm2p = 1'b1;
    tdmPatt = 8'h3C;
    tdmMask = 8'hFF;
    passThru = 1'b0;
    sergenEnable = 1'b0;
    serjitEnable = 1'b0;
    regMonEnable = 1'b1;
    regPollDelay = 32'd1000;
    directData = 1'b0;

    begin : file_block

    file = $fopenr(configFile);
    if (file == 0)
        disable file_block;

    end

    while (!$feof(file)) begin
        if (!cfgRdy) begin
            r = $fscanf(file, "%s", line);
            case (line)
            "passThru":
            begin
                r = $fscanf(file, "%d", data);
                passThru = data;
            end
            "sergen":
            begin
                r = $fscanf(file, "%d", data);
                sergenEnable = data;
            end
            "serjit":
            begin
                r = $fscanf(file, "%d", data);
                serjitEnable = data;
            end
            "regMonEnable":
            begin
                r = $fscanf(file, "%d", data);
                regMonEnable = data;
            end
            "regPollDelay":
            begin
                r = $fscanf(file, "%d", data);
                regPollDelay = data;
            end
            "p2tdm":
            begin
                r = $fscanf(file, "%d", data);
                p2tdm = data;
            end
            "tdm2p":
            begin
                r = $fscanf(file, "%d", data);
                tdm2p = data;
            end
            "tdmPatt":
            begin
                r = $fscanf(file, "%d", data);
                tdmPatt = data;
            end
            "tdmMask":
            begin
                r = $fscanf(file, "%d", data);
                tdmMask = data;
            end
            "directData":
            begin
                directData = 1'b1;
                cfgRdy = 1'b1;
            end
            default:
            begin
                //$display("ERROR: Unknown command '%0s'", line);
                error = 1;
            end
            endcase
            $display ("%-d: %-s %-d", r, line, data);
        end // if cfgRdy
        else if (cfgRdy) begin
            if (error) begin
                // cfgRdy, but error was set, so seek to EOF to exit loop
                r = $fseek(file, 0, 2);
            end
            else begin
                r = $fscanf(file, "%08h\n", data);
                //$display ("%-d: %-h", r, data);

                // wait until out of ready
                wait (ddataEn == 1'b1);

                for (i=0; i<8; i=i+1) begin
                    // Sync to clock, then write data
                    @(negedge sclk) ddata = data[i];
                    //$display("%t: ddata = %d", $time, data[i]);
                end
            end // if (!error)
        end // if (cfgRdy)
    end // while not EOF

    if (error) $finish(2);
    #1 cfgRdy = 1'b1;   // force cfgRdy, if no data was given
end

endmodule

