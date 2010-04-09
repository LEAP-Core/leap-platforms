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
`include "rrr_common.bsh"

// ============== Physical Channel ===============

// interface
interface PHYSICAL_CHANNEL;
    
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);
        
endinterface

// module
module mkPhysicalChannel#(PHYSICAL_DRIVERS drivers)
    // interface
        (PHYSICAL_CHANNEL);
  
   // shortcut to drivers
   JTAG_DRIVER jtagDriver = drivers.jtagDriver;
  
   DEMARSHALLER#(JTAGWord,UMF_CHUNK) jtagIncoming  <- mkDeMarshaller;
   MARSHALLER#(UMF_CHUNK, JTAGWord)  jtagOutgoing  <- mkMarshaller;
   
   // no. jtag words to assemble a umf chunk
   UMF_MSG_LENGTH no_jtag_words = fromInteger(valueof(SizeOf#(UMF_CHUNK))/valueOf(SizeOf#(JTAGWord)));

   rule startNewDemarshalling;
      jtagIncoming.start(no_jtag_words); // only work if UMF_CHUNK are multiple of JTAGWord
   endrule
   
   rule sendToJtag;
      let x = jtagOutgoing.first();
      jtagDriver.send(x);
      jtagOutgoing.deq();
   endrule
   
   rule recvFromJtag;
      let x <- jtagDriver.receive();
      jtagIncoming.insert(x);
   endrule

   method Action write(UMF_CHUNK data);
      jtagOutgoing.enq(data,no_jtag_words);
   endmethod
   
   method ActionValue#(UMF_CHUNK) read();
      let x <- jtagIncoming.readAndDelete();
      return x;
   endmethod
   
endmodule