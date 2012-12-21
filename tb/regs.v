/* register control include
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: n/a

Purpose: 
    Register configuration include for tb environment

Function:
    Included by the tb top-level, it is has tasks to write and check
    configurations from the registers.

    THIS MODULE IS NOT SYNTHESIZABLE. It is just for verification.
*/

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
    // Set TDM 2 P config
    read_reg(
        .addr(32'h0000_0000),
        .data(read_data)
    );
    if (read_data != {tdm2pEnable, 15'd0, tdm2pClkMask, tdm2pClkPatt}) begin
        $display ("ERROR: %t: Read data does not match written config (a: %08x, r: %08x, e: %08x)", $time
                32'h0000_0000, read_data, {tdm2pEnable, 15'd0, tdm2pClkMask, tdm2pClkPatt});
    end

    // Set P 2 TDM config
    read_reg(
        .addr(32'h0000_0100),
        .data(read_data)
    );
    if (read_data != {p2tdmEnable, 31'd0}) begin
        $display ("ERROR: %t: Read data does not match written config (a: %08x, r: %08x, e: %08x)", $time
                32'h0000_0100, read_data, {p2tdmEnable, 31'd0});
    end

    // Set Gain and Balance
    read_reg(
        .addr(32'h0000_0200),
        .data(read_data)
    );
    if (read_data != {8'd0, bal[7:0], gain[31:0]}) begin
        $display ("ERROR: %t: Read data does not match written config (a: %08x, r: %08x, e: %08x)", $time
                32'h0000_0200, read_data, {8'd0, bal[7:0], gain[31:0]});
    end

    read_reg(
        .addr(32'h0000_0204),
        .data(read_data)
    );
    if (read_data != {8'd0, bal[15:8], gain[47:32]}) begin
        $display ("ERROR: %t: Read data does not match written config (a: %08x, r: %08x, e: %08x)", $time
                32'h0000_0204, read_data, {8'd0, bal[15:8], gain[47:32]});
    end

    read_reg(
        .addr(32'h0000_0208),
        .data(read_data)
    );
    if (read_data != {8'd0, bal[23:16], gain[55:48]}) begin
        $display ("ERROR: %t: Read data does not match written config (a: %08x, r: %08x, e: %08x)", $time
                32'h0000_0208, read_data, {8'd0, bal[23:16], gain[55:48]});
    end

    read_reg(
        .addr(32'h0000_020c),
        .data(read_data)
    );
    if (read_data != {8'd0, bal[31:24], gain[63:56]}) begin
        $display ("ERROR: %t: Read data does not match written config (a: %08x, r: %08x, e: %08x)", $time
                32'h0000_020c, read_data, {8'd0, bal[31:24], gain[63:56]});
    end

    // Set TDM MUX
    read_reg(
        .addr(32'h0000_0300),
        .data(read_data)
    );
    if (read_data != {31'd0, sel}) begin
        $display ("ERROR: %t: Read data does not match written config (a: %08x, r: %08x, e: %08x)", $time
                32'h0000_0300, read_data, {31'd0, sel});
    end
end
endtask
