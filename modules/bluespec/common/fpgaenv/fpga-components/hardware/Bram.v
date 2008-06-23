// Copyright 2006--2008, University of Texas at Austin.  All rights reserved.
// Author(s): Eric Johnson

module DualPortedBram (clka, clkb, ena, enb, wea, web, addra, addrb, dia, dib, doa, dob);

   parameter dataWidth = 36;
   parameter addrWidth = 9;
   parameter depth = 1 << addrWidth;

   input clka, clkb, ena, enb, wea, web;
   input [addrWidth-1:0] addra, addrb;
   input [dataWidth-1:0]     dia, dib;
   output [dataWidth-1:0]    doa, dob;
   reg [dataWidth-1:0]       ram [depth-1:0];
   reg [dataWidth-1:0]       doa, dob;

   always @(posedge clka) begin
      if (ena) begin
        if (wea)
            ram[addra] <= dia;
        doa <= ram[addra];
      end
   end

   always @(posedge clkb) begin
      if (enb) begin
        if (web)
            ram[addrb] <= dib;
        dob <= ram[addrb];
      end
   end

endmodule

module Bram
(
    CLK,
    RST_N,
    CLK_GATE,
    rdya,
    rdyb,
    ena,
    enb,
    wea,
    web,
    addra,
    addrb,
    dia,
    dib,
    rdyRespa,
    rdyRespb,
    doa,
    dob
);

    parameter dataWidth = 36;
    parameter addrWidth = 9;
    parameter depth = 1 << addrWidth;

    input CLK, RST_N, CLK_GATE, ena, enb, wea, web;
    output rdya, rdyb, rdyRespa, rdyRespb;
    input [addrWidth-1:0] addra, addrb;
    input [dataWidth-1:0]     dia, dib;
    output [dataWidth-1:0]    doa, dob;

    assign rdya = 1;
    assign rdyb = 1;
    assign rdyRespa = 1;
    assign rdyRespb = 1;

    DualPortedBram#(.dataWidth(dataWidth), .addrWidth(addrWidth), .depth(depth)) dualPortedBram (.clka(CLK), .clkb(CLK), .ena(ena), .enb(enb), .wea(wea), .web(web),
                                                                                                 .addra(addra), .addrb(addrb), .dia(dia), .dib(dib), .doa(doa), .dob(dob));
endmodule
