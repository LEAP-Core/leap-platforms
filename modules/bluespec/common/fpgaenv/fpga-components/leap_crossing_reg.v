//
// Copyright (c) 2015, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//


//
// leap_crossing_reg --
//   A verilog implementation of  Bluespec's mkNullCrossingReg, which allows us to make 
//   timing assertions during physical synthesis.  
// 

module leap_crossing_reg#(
    parameter WIDTH = 32,  
    parameter INITIAL_VALUE = 32'haaaaaaaa
)

(
    input                CLK, 
    input                RST_N, 
    input                CLK_DST, 
    input [WIDTH - 1:0]  writeData, 
    input                writeEnable,  
    output [WIDTH - 1:0] readData, 
    output [WIDTH - 1:0] readDataCrossed
);
  
   reg [WIDTH - 1:0] crossingRegDst;
   reg [WIDTH - 1:0] crossingRegSrc;

   assign readData = crossingRegSrc;
   assign readDataCrossed = crossingRegDst;
  
   // TODO: There's likely a better way to get a reference on CLK_DST.
   // Eventually, we should remove this register. 
   always@(posedge CLK_DST)
   begin
       if(~RST_N)
       begin
           crossingRegDst <= INITIAL_VALUE;
       end
       else 
       begin
           crossingRegDst <= crossingRegSrc;
       end                
   end
      
   always@(posedge CLK)
   begin
      
       if(~RST_N)
       begin
           crossingRegSrc <= INITIAL_VALUE;
       end
       else if(writeEnable)
       begin
           crossingRegSrc <= writeData;
       end           
   end

endmodule