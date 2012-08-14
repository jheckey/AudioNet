// Config
reg              tdm2pEnable;
reg  [7:0]       tdm2pClkMask;
reg  [7:0]       tdm2pClkPatt;
reg              p2tdmEnable;
reg  [63:0]      gain;
reg  [31:0]      bal;
reg              sel;

// Status
reg  [15:0]      p2tdmRetrans;
reg  [15:0]      p2tdmDropped;

task writeTbConfig();
begin
    // Set TDM 2 P config
    write_reg(
        .addr(32'h0000_0000),
        .data({tdm2pEnable, 15'd0, tdm2pClkMask, tdm2pClkPatt})
    );

    // Set P 2 TDM config
    write_reg(
        .addr(32'h0000_0100),
        .data({p2tdmEnable, 31'd0)
    );

    // Set Gain and Balance
    write_reg(
        .addr(32'h0000_0200),
        .data({8'd0, bal[7:0], gain[31:0]})
    );

    write_reg(
        .addr(32'h0000_0204),
        .data({8'd0, bal[15:8], gain[47:32]})
    );

    write_reg(
        .addr(32'h0000_0208),
        .data({8'd0, bal[23:16], gain[55:48]})
    );

    write_reg(
        .addr(32'h0000_020c),
        .data({8'd0, bal[31:24], gain[63:56]})
    );

    // Set TDM MUX
    write_reg(
        .addr(32'h0000_0300),
        .data({31'd0, sel})
    );
end
endtask

task checkTbRegs();
begin
end
endtask
