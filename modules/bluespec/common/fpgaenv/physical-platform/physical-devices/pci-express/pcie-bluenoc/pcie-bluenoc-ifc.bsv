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

import MsgFormat::*;
import PCIE::*;

`include "awb/provides/pcie_bluenoc_ifc.bsh"
`include "awb/provides/umf.bsh"

//
// Common interface definitions used by top level BlueNoC PCIe bridge and the
// lower-level devices.
//

typedef `PCIE_BYTES_PER_BEAT PCIE_BYTES_PER_BEAT;
typedef `PCIE_LANES PCIE_LANES;

        
//
// PCIE_ --
//   Expose the PCIe device as a network port.
// 
interface PCIE_LOW_LEVEL_DRIVER;
    interface MsgPort#(PCIE_BYTES_PER_BEAT) noc;

    interface Clock clock;
    interface Reset reset;
endinterface


// interface
interface PCIE_DRIVER;
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);

    // this interface needed for LIM compiler.
    method UMF_CHUNK first();
    method Action    deq();
    method Bool      write_ready();
   
    interface Clock clock;
    interface Reset reset;

endinterface

//
// BNOC_PCIE_DEV --
//
//   Internal interface for connection to the BlueNoC bridge and PCIe device.
//
interface BNOC_PCIE_DEV#(numeric type n_BPB);
    interface PCIE_LOW_LEVEL_DRIVER driver;
    interface PCIE_EXP#(PCIE_LANES) pcie_exp;
endinterface
