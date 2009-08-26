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

import FIFO::*;
import Vector::*;

`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/rrr.bsh"

`include "asim/rrr/client_stub_ASSERTIONS.bsh"
`include "asim/rrr/service_ids.bsh"
`include "asim/dict/ASSERTIONS.bsh"

// Assertions

// A way to report to the outside world when something has gone wrong.


// ASSERTION_SEVERITY

// The severity of an assertion. This could be used to filter things out.

typedef enum
{
    ASSERT_NONE,
    ASSERT_MESSAGE,
    ASSERT_WARNING,
    ASSERT_ERROR
}
    ASSERTION_SEVERITY 
        deriving (Eq, Bits);


instance Ord#(ASSERTION_SEVERITY);

  function Bool \< (ASSERTION_SEVERITY x, ASSERTION_SEVERITY y) = pack(x) < pack(y);

  function Bool \> (ASSERTION_SEVERITY x, ASSERTION_SEVERITY y) = pack(x) > pack(y);

  function Bool \<= (ASSERTION_SEVERITY x, ASSERTION_SEVERITY y) = pack(x) <= pack(y);

  function Bool \>= (ASSERTION_SEVERITY x, ASSERTION_SEVERITY y) = pack(x) >= pack(y);

endinstance

// Vector of severity values for assertions baseID + index
typedef Vector#(`ASSERTIONS_PER_NODE, ASSERTION_SEVERITY) ASSERTION_NODE_VECTOR;

interface ASSERTIONS;
    method Action assertionNodeValues(ASSERTIONS_DICT_TYPE baseID, ASSERTION_NODE_VECTOR values);
endinterface

// mkAssertionsIO

// A module which serially passes Assertion failures back to the software.

module mkAssertionsDevice#(LowLevelPlatformInterface llpi)
    // interface:
        (ASSERTIONS);

    //***** State Elements *****
  
    // Communication to our RRR server
    ClientStub_ASSERTIONS clientStub <- mkClientStub_ASSERTIONS(llpi.rrrClient);
  
    Reg#(Bit#(32)) fpgaCC <- mkReg(0);
  
    // ***** Rules *****
  
    // countCC
  
    rule countCC (True);

        fpgaCC <= fpgaCC + 1;

    endrule
  

    // assertionNodeValues

    // Get a set of values from an individual assertion checker.
    // Pass assertions on to software.  Here we let the software deal with
    // the relatively complicated base ID and assertions vector.

    method Action assertionNodeValues(ASSERTIONS_DICT_TYPE baseID, ASSERTION_NODE_VECTOR assertions);

        clientStub.makeRequest_Assert(zeroExtend(pack(baseID)),
                                      fpgaCC,
                                      zeroExtend(pack(assertions)));

    endmethod

endmodule
