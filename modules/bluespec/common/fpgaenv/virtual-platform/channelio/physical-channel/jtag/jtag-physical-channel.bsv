//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

`include "physical_platform.bsh"
`include "jtag_device.bsh"
`include "umf.bsh"

// ============== Physical Channel ===============

// interface
interface PHYSICAL_CHANNEL;
    
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);
        
endinterface

typedef Bit#(TLog#(TAdd#(TDiv#(SizeOf#(UMF_CHUNK),4),1))) UMF_COUNTER;

// module
module mkPhysicalChannel#(PHYSICAL_DRIVERS drivers)
    // interface
        (PHYSICAL_CHANNEL);
   
   // no. jtag words to assemble a umf chunk
   UMF_COUNTER no_jtag_words = fromInteger(valueof(SizeOf#(UMF_CHUNK))/4);

   Reg#(UMF_CHUNK)      jtagIncoming      <- mkReg(0);
   Reg#(UMF_COUNTER)    jtagIncomingCount <- mkReg(0); 
   Reg#(UMF_CHUNK)      jtagOutgoing      <- mkReg(0);
   Reg#(UMF_COUNTER)    jtagOutgoingCount <- mkReg(0);       
   Reg#(Bool)           init              <- mkReg(False);
   
   // send the first character
   rule sendInit (!init);
      drivers.jtagDriver.send(zeroExtend(jtagOutgoingCount)+65);
      jtagOutgoingCount <= jtagOutgoingCount + 1;
      if (jtagOutgoingCount == no_jtag_words - 1)
         init <= True;
   endrule
   
   rule sendToJtag (init && jtagOutgoingCount != no_jtag_words);
      Bit#(4) x = truncate(jtagOutgoing);
      jtagOutgoing <= jtagOutgoing >> 4;
      JTAGWord jtag_x = zeroExtend(x) ^ 64;
      drivers.jtagDriver.send(jtag_x);
      jtagOutgoingCount <= jtagOutgoingCount + 1;
   endrule
   
   rule recvFromJtag (jtagIncomingCount != no_jtag_words);
      JTAGWord x <- drivers.jtagDriver.receive();
      Bit#(4) truncated_x = truncate(x);
      jtagIncoming <= (jtagIncoming >> 4) ^ {truncated_x,0};
      jtagIncomingCount <= jtagIncomingCount + 1;
   endrule

   method Action write(UMF_CHUNK data) if (jtagOutgoingCount == no_jtag_words && init);
      jtagOutgoing <= data;
      jtagOutgoingCount <= 0;
   endmethod
   
   method ActionValue#(UMF_CHUNK) read() if (jtagIncomingCount == no_jtag_words);
      jtagIncomingCount <= 0;
      return jtagIncoming;
   endmethod
   
endmodule