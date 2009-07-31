/*
Copyright (c) 2007 MIT

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

Author: Nirav Dave
*/

module bramfeeder(CLK,
		    RST,

		    ppcMessageInput_put,
		    EN_ppcMessageInput_put,
		    RDY_ppcMessageInput_put,

		    EN_ppcMessageOutput_get,
		    ppcMessageOutput_get,
		    RDY_ppcMessageOutput_get,
		  
		    bramInitiatorWires_bramRST,
		    bramInitiatorWires_bramAddr,
		    bramInitiatorWires_bramDout,
		    bramInitiatorWires_bramWEN,
		    bramInitiatorWires_bramEN,
		    bramInitiatorWires_bramCLK,
		  bramInitiatorWires_bramDin);
   

  input  CLK;
  input  RST;

  // action method ppcMessageInput_put
  input  [31 : 0] ppcMessageInput_put;
  input  EN_ppcMessageInput_put;
  output RDY_ppcMessageInput_put;

  // actionvalue method ppcMessageOutput_get
  input  EN_ppcMessageOutput_get;
  output [31 : 0] ppcMessageOutput_get;
  output RDY_ppcMessageOutput_get;
  
  
  // action method bramTargetWires_bramIN
  output  [31 : 0] bramInitiatorWires_bramAddr;
  output  [31 : 0] bramInitiatorWires_bramDout;
  output  [3 : 0] bramInitiatorWires_bramWEN;
  output  bramInitiatorWires_bramEN;
  output  bramInitiatorWires_bramCLK;    
  output  bramInitiatorWires_bramRST;

  // value method bramTargetWires_bramOUT
  input [31 : 0] bramInitiatorWires_bramDin;
   
  wire [13:0] bramInitiatorWires_bramAddr_our;
  assign bramInitiatorWires_bramAddr = {16'h00000,bramInitiatorWires_bramAddr_our, 2'b00};


wire RST_N;
assign RST_N = ~RST;

mkBRAMFeeder  m(
	        .CLK(CLK),
	        .RST_N(RST_N),
		.ppcMessageInput_put(ppcMessageInput_put),
		.EN_ppcMessageInput_put(EN_ppcMessageInput_put),
		.RDY_ppcMessageInput_put(RDY_ppcMessageInput_put),
		.EN_ppcMessageOutput_get(EN_ppcMessageOutput_get),
		.ppcMessageOutput_get(ppcMessageOutput_get),
		.RDY_ppcMessageOutput_get(RDY_ppcMessageOutput_get),
		.bramInitiatorWires_bramAddr(bramInitiatorWires_bramAddr_our),
		.bramInitiatorWires_bramDout(bramInitiatorWires_bramDout),
		.bramInitiatorWires_bramWEN(bramInitiatorWires_bramWEN),
		.bramInitiatorWires_bramEN(bramInitiatorWires_bramEN),
                .CLK_bramInitiatorWires_bramCLK(bramInitiatorWires_bramCLK),
		.bramInitiatorWires_bramRST(bramInitiatorWires_bramRST),
		.bramInitiatorWires_bramDin(bramInitiatorWires_bramDin)
		);

endmodule