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

// This module interfaces to the SMA cables on the
// XUPV5. However only certain of the generated verilog and ucf files
// are needed to characterize this interface, and it can be used a model 
// for high-speed board to board serial on other development boards. The 
// device interface consists of a simple FIFO with guaranteed transport to
// the other device. This module is slightly complicated by the need to 
// instantiate dummy serial modules to route clock to the SMA GTP.


import Clocks::*;
import FIFOF::*;
import FIFO::*;
import FIFOLevel::*;
import Connectable::*;
import GetPut::*;
import Vector::*;

`include "awb/provides/aurora_flowcontrol.bsh"
`include "awb/provides/aurora_driver.bsh"
`include "awb/provides/librl_bsv_base.bsh"

typedef 3 InterfaceWords;
typedef `AURORA_INTERFACE_WIDTH InterfaceWidth;

typedef AURORA_DRIVER#(AURORA_INTERFACE_WIDTH#(InterfaceWords, InterfaceWidth)) SIMULATION_COMMUNICATION_DRIVER;
typedef Empty         SIMULATION_COMMUNICATION_WIRES;

interface SIMULATION_COMMUNICATION_DEVICE;
   interface SIMULATION_COMMUNICATION_DRIVER driver;
   interface SIMULATION_COMMUNICATION_WIRES  wires;
endinterface
 
module mkSimulationCommunicationDevice#(String outgoing, String incoming) (SIMULATION_COMMUNICATION_DEVICE);

    AURORA_SINGLE_DEVICE_UG#(InterfaceWidth) ug_device <- mkAURORA_SINGLE_UG(outgoing, incoming);

    NumTypeParam#(InterfaceWords) interfaceWidth = ?;
    let auroraFlowcontrol <- mkAURORA_FLOWCONTROL(ug_device, interfaceWidth);

    interface driver = auroraFlowcontrol.driver;
 
endmodule

