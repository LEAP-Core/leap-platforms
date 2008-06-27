module Bram
(
    CLK,
    RST_N,
    CLK_GATE,
    readEnable,
    readAddr,
    readReady,
    readData,
    readDataEnable,
    readDataReady,
    writeEnable,
    writeAddr,
    writeData,
    writeReady,
    noPendingBool
);
    parameter dataSize = 32;
    parameter addrSize = 9;
    parameter numRows = 512;

    input CLK, RST_N, CLK_GATE;
    input  readEnable;
    input  [addrSize-1:0] readAddr;
    output readReady;
    output [dataSize-1:0] readData;
    input  readDataEnable;
    output readDataReady;
    input  writeEnable;
    input  [addrSize-1:0] writeAddr;
    input  [dataSize-1:0] writeData;
    output writeReady;
    output noPendingBool;

    reg [dataSize-1:0] readData;

    reg [dataSize-1:0] ram [numRows-1:0];

    assign readReady = 1;
    assign readDataReady = 1;
    assign writeReady = 1;

    assign noPendingBool = 1;

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
