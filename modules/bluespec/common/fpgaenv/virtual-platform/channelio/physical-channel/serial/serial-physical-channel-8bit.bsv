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
`include "serial_device.bsh"
`include "umf.bsh"

// ============== Physical Channel ===============

// interface
interface PHYSICAL_CHANNEL;
    
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);
        
endinterface

typedef Bit#(TLog#(TAdd#(TDiv#(SizeOf#(UMF_CHUNK),8),1))) UMF_COUNTER;


// module
module mkPhysicalChannel#(PHYSICAL_DRIVERS drivers)
    // interface
        (PHYSICAL_CHANNEL);
   
   // no. jtag words to assemble a umf chunk
   UMF_COUNTER no_jtag_words = fromInteger(valueof(SizeOf#(UMF_CHUNK))/8);
   
   SerialWord password[4] = {97,98,99,100};
   SerialWord counterword[4] = {65,66,67,68};

   Reg#(UMF_CHUNK)      jtagIncoming      <- mkReg(0);
   Reg#(UMF_COUNTER)    jtagIncomingCount <- mkReg(0); 
   Reg#(UMF_CHUNK)      jtagOutgoing      <- mkReg(0);
   Reg#(UMF_COUNTER)    jtagOutgoingCount <- mkReg(0);       
   Reg#(Bool)           init              <- mkReg(False);
   Reg#(Bool)           sent              <- mkReg(False);
   PulseWire            rxInit            <- mkPulseWire;   


   // send the first character
   rule sendInit (!init && !rxInit);
      if(jtagOutgoingCount == 0 || !sent)
        begin 
          drivers.serialDriver.send(password[jtagOutgoingCount]);
          sent <= True;
        end
   endrule

   
   rule recvInit (!init);
      let inVal <- drivers.serialDriver.receive();
      rxInit.send; 
      sent <= False;
      if(inVal == counterword[jtagOutgoingCount])
        begin
          jtagOutgoingCount <= jtagOutgoingCount + 1;
          if (jtagOutgoingCount == no_jtag_words - 1)
            init <= True;
        end
      else
        begin
          jtagOutgoingCount <= 0;
        end 
   endrule
   
   rule sendToJtag (init && jtagOutgoingCount != no_jtag_words);
      Bit#(8) x = truncate(jtagOutgoing);
      jtagOutgoing <= jtagOutgoing >> 8;
      SerialWord jtag_x = x;
      drivers.serialDriver.send(jtag_x);
      jtagOutgoingCount <= jtagOutgoingCount + 1;
   endrule
   
   rule recvFromJtag (jtagIncomingCount != no_jtag_words);
      SerialWord x <- drivers.serialDriver.receive();
      jtagIncoming <= (jtagIncoming >> 8) ^ {x,0};
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