//
// Copyright (c) 2014, Intel Corporation
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
// A general wrapper for Xilinx DDR memories, providing clock transition
// and request timing managagement.  The wrapper instantiates device-specific
// drivers.
//

import Clocks::*;


typedef Empty DDR_WIRES;
typedef Empty DDR_DRIVER;

`include "awb/provides/ddr_sdram_definitions.bsh"

//
// DDR_DEVICE --
//     By convention a device is both a driver and a wires interface.
//     Drivers are exposed as a vector of devices since they may be accessed
//     independently by clients.  The wires are exposed as a monolithic
//     type since they will typically be tied down to pins and not used
//     elsewhere in the design.
//
interface DDR_DEVICE;
    interface DDR_DRIVER driver;
    interface DDR_WIRES wires;
endinterface


//
// mkDDRDevice
//
module mkDDRDevice#(DDRControllerConfigure ddrConfig)
    // interface:
    (DDR_DEVICE);

endmodule