//
// Copyright (C) 2011 Massachusetts Institute of Technology
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

typedef AURORA_DRIVER SIMULATION_COMMUNICATION_DRIVER;
typedef Empty         SIMULATION_COMMUNICATION_WIRES;

interface SIMULATION_COMMUNICATION_DEVICE;
   interface SIMULATION_COMMUNICATION_DRIVER driver;
   interface SIMULATION_COMMUNICATION_WIRES  wires;
endinterface
 
module mkSimulationCommunicationDevice#(String outgoing, String incoming) (SIMULATION_COMMUNICATION_DEVICE);

    let ug_device <- mkAURORA_SINGLE_UG(outgoing, incoming);

    let auroraFlowcontrol <- mkAURORA_FLOWCONTROL(ug_device);

    interface driver = auroraFlowcontrol.driver;
 
endmodule

