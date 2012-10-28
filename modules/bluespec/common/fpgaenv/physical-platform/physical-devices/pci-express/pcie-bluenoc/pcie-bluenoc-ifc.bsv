//
// Copyright (C) 2012 Intel Corporation
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

import MsgFormat::*;
import PCIE::*;

`include "awb/provides/pcie_bluenoc_ifc.bsh"


//
// Common interface definitions used by top level BlueNoC PCIe bridge and the
// lower-level devices.
//

typedef `PCIE_BYTES_PER_BEAT PCIE_BYTES_PER_BEAT;
typedef `PCIE_LANES PCIE_LANES;

        
//
// PCIE_DRIVER --
//   Expose the PCIe device as a network port.
// 
interface PCIE_DRIVER;
    interface MsgPort#(PCIE_BYTES_PER_BEAT) noc;

    interface Clock clock;
    interface Reset reset;
endinterface


//
// BNOC_PCIE_DEV --
//
//   Internal interface for connection to the BlueNoC bridge and PCIe device.
//
interface BNOC_PCIE_DEV#(numeric type n_BPB);
    interface PCIE_DRIVER driver;
    interface PCIE_EXP#(PCIE_LANES) pcie_exp;
endinterface
