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

import FIFO::*;

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
    FIFO#(UMF_CHUNK) loopfifo <- mkSizedFIFO(16);
    
    rule enqueue;
      let data <- serialDriver.receive;
      loopfifo.enq(data);
    endrule

    rule dequeue ;
      serialDriver.send(loopfifo.first);
      loopfifo.deq;
    endrule

endmodule
