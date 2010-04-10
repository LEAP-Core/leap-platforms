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

typedef Bit#(TLog#(TAdd#(TDiv#(SizeOf#(UMF_CHUNK),SizeOf#(JTAGWord)),1))) UMF_COUNTER;

// module
module mkPhysicalChannel#(PHYSICAL_DRIVERS drivers)
    // interface
        (PHYSICAL_CHANNEL);
   
   // no. jtag words to assemble a umf chunk
   UMF_COUNTER no_jtag_words = fromInteger(valueof(SizeOf#(UMF_CHUNK))/valueOf(SizeOf#(JTAGWord)));

   Reg#(UMF_CHUNK)      jtagIncoming      <- mkReg(0);
   Reg#(UMF_COUNTER)    jtagIncomingCount <- mkReg(0); 
   Reg#(UMF_CHUNK)      jtagOutgoing      <- mkReg(0);
   Reg#(UMF_COUNTER)    jtagOutgoingCount <- mkReg(no_jtag_words);       
   
   rule sendToJtag (jtagOutgoingCount != no_jtag_words);
      JTAGWord x = truncate(jtagOutgoing);
      jtagOutgoing <= jtagOutgoing >> valueOf(SizeOf#(JTAGWord));
      jtagOutgoingCount <= jtagOutgoingCount + 1;
   endrule
   
   rule recvFromJtag (jtagIncomingCount != no_jtag_words);
      JTAGWord x <- drivers.jtagDriver.receive();
      jtagIncoming <= (jtagIncoming << valueOf(SizeOf#(JTAGWord))) + zeroExtend(x);
      jtagIncomingCount <= jtagIncomingCount + 1;
   endrule

   method Action write(UMF_CHUNK data) if (jtagOutgoingCount == no_jtag_words);
      jtagOutgoing <= data;
      jtagOutgoingCount <= 0;
   endmethod
   
   method ActionValue#(UMF_CHUNK) read() if (jtagIncomingCount == no_jtag_words);
      jtagIncomingCount <= 0;
      return jtagIncoming;
   endmethod
   
endmodule