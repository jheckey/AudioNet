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

