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
        regPollDelay [int]  - number of cycles to wait between polling registers (default 1000)

    THIS MODULE IS NOT SYNTHESIZABLE. It is just for verification.
*/

module tbconfig (
    input  wire [8*256-1:0] configFile,

    output reg              passThru,
    output reg              sergenEnable,
    output reg              serjitEnable,
    output reg              regMonEnable,
    output reg  [31:0]      regPollDelay,
    output reg              directData
);

integer file, r;
reg [80*8:1] line;
reg [31:0] data;

initial begin
    passThru = 1'b0;
    sergenEnable = 1'b0;
    serjitEnable = 1'b0;
    regMonEnable = 1'b1;
    regPollDelay = 32'd1000;

    begin : file_block

    file = $fopenr(configFile);
    if (file == `NULL)
        disable file_block;

    while (!$feof(file)) begin
        r = $fscanf(file, " %s %d \n", line, data);
        case (line)
        "passThru":
            passThru = data;
        "sergen":
            sergenEnable = data;
        "serjit":
            serjitEnable = data;
        "regMonEnable":
            regMonEnable = data;
        "regPollDelay":
            regPollDelay = data;
        default:
            $display("Unknown command '%0s'", line);
        endcase
    end // while not EOF

    r = $fcloser(file);
end

endmodule

