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

`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/rrr.bsh"

`include "asim/rrr/server_stub_PARAMS.bsh"

`include "asim/dict/PARAMS.bsh"


// RRR request DYN_PARAM
typedef struct
{
    PARAMS_DICT_TYPE paramID;
    UINT64 value;
}
    DYN_PARAM
               deriving (Eq, Bits);


interface DYNAMIC_PARAMETERS;

    // server methods
    method DYN_PARAM getParameter();
    method Action nextParameter();

endinterface

// mkDynamicParameters
module mkDynamicParametersDevice#(LowLevelPlatformInterface llpi)
    // interface:
        (DYNAMIC_PARAMETERS);

    // Communication to our RRR server
    ServerStub_PARAMS server_stub <- mkServerStub_PARAMS(llpi.rrrServer);
  
    method DYN_PARAM getParameter();

        let req = server_stub.peekRequest_sendParam();
        DYN_PARAM p;
        p.paramID = truncate(pack(req.paramID));
        p.value = req.value;
        return p;
    
    endmethod
    
    method Action nextParameter();
    
        let req <- server_stub.acceptRequest_sendParam();
        server_stub.sendResponse_sendParam(0);

    endmethod

endmodule
