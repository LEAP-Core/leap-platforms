(* ram_style = "block" *)

module Bram
(
    CLK,
    RST_N,
    CLK_GATE,
    readEnable,
    readAddr,
    readData,
    readDataEnable,
    writeEnable,
    writeAddr,
    writeData
);
    parameter dataSize = 32;
    parameter addrSize = 9;
    parameter numRows = 512;

    input CLK, RST_N, CLK_GATE;
    input  readEnable;
    input  [addrSize-1:0] readAddr;
    output [dataSize-1:0] readData;
    input  readDataEnable;
    input  writeEnable;
    input  [addrSize-1:0] writeAddr;
    input  [dataSize-1:0] writeData;

    reg [dataSize-1:0] readData;

    reg [dataSize-1:0] ram [numRows-1:0];

    always@(posedge CLK)
    begin
        if(RST_N)
            readData <= ram[readAddr];
    end

    always@(posedge CLK)
    begin
        if(writeEnable)
            ram[writeAddr] <= writeData;
    end
endmodule
