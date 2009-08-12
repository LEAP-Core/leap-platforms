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

// module
module mkPhysicalChannel#(PHYSICAL_DRIVERS drivers)
    // interface
        (PHYSICAL_CHANNEL);
  
  // shortcut to drivers
  SERIAL_DRIVER serialDriver = drivers.serialDriver;


  Reg#(Bool)    initialized <- mkReg(False);
  Reg#(Bit#(12)) count      <- mkReg(0);
  
  //scheme is pos 0 0xF0 HW -> SW
  //          pos 1 0xCA SW -> HW
  //          pos 2 0x08 HW -> SW
  
  rule sendPulse(!initialized);
    count <= count + 1;
    if (count == 0)
      begin
	serialDriver.send(32'hDEADBEEF);
      end
  endrule


  rule getResp(!initialized);
    let x<- serialDriver.receive();
    if (x == 32'h0505CAFE) // woo. A response Send a token and we're done 
      begin
	serialDriver.send(32'h08675309);
	initialized <= True;
      end   
  endrule  
 
  method ActionValue#(UMF_CHUNK) read() if (initialized);
    let x <- serialDriver.receive();
    return x;
  endmethod

  method Action write(UMF_CHUNK x) if (initialized);
    serialDriver.send(x);
  endmethod
  
endmodule
