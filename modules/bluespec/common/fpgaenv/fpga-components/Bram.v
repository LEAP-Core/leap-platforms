//
// Dual-port RAM with false synchronous read.  We do not connect the read
// output of the port used for writing.
//
// Xst seems not to infer block RAM using the synchronous read examples
// given in the manual, so we use the false synchronous version.
//

(* ram_style = "block" *)

module Bram
(
    CLK,
    RST_N,
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

    input CLK, RST_N;
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
        if(writeEnable)
            ram[writeAddr] <= writeData;
        readData <= ram[readAddr];
    end

endmodule
