/* TDM mux
Copyright: Hectic Tech, 2012, all rights reserved
Author: Jeff Heckey (jheckey@gmail.com)

Module: tdmMux

Purpose: 
    Simply muxes two different input streams into a single output

Function:
    In a system perspective, this is used to set a bypass mode from
    the tdm2p to p2tdm directly, instead of from the registers. This
    is used for testing, potentially, as a diagnostic, but will most
    likely have no true functional purpose.
*/

module tdmMux (
    input  wire         sel,
    input  wire         tdmPdataValid0,
    input  wire [255:0] tdmPdata0,
    input  wire         tdmPdataValid1,
    input  wire [255:0] tdmPdata1,
    output wire         tdmPdataValidX,
    output wire [255:0] tdmPdataX
);

assign tdmPdataValidX = (sel) ? tdmPdataValid1 : tdmPdataValid0;
assign tdmPdataX      = (sel) ? tdmPdata1      : tdmPdata0;

endmodule

