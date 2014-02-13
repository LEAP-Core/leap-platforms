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
// Pass PCIe I/O wires from the top-level to the PCIe driver.  This involves
// a fictitious clock-domain crossing.  In order for the methods to be
// always enabled Bluespec must associate a clock with them.  Only the raw
// differential clock inputs are available at the top.  Since the clock
// is never used we can associate the methods with any clock available at
// the top level.
//

interface PCIE_BURY;

    // Wires to be sent to the top level

    (* always_enabled, always_ready *)
    method Action rxp_wire(Bit#(8) i);
    (* always_enabled, always_ready *)
    method Action rxn_wire(Bit#(8) i);
    (* always_enabled, always_ready *)
    method Bit#(8) txp_wire;
    (* always_enabled, always_ready *)
    method Bit#(8) txn_wire;

    (* always_enabled, always_ready *)
    method Bit#(8) rxp_dev();
    (* always_enabled, always_ready *)
    method Bit#(8) rxn_dev();
    (* always_enabled, always_ready *)
    method Action txp_dev(Bit#(8) i);
    (* always_enabled, always_ready *)
    method Action txn_dev(Bit#(8) i);

endinterface

import "BVI" pcie_bury = module mkPCIE_BURY#(Clock topClock, Clock devClock)
    // Interface:
    (PCIE_BURY);
  
    input_clock tClock() = topClock;
    input_clock dClock() = devClock;

    default_clock no_clock;
    default_reset no_reset;

    method rxp_wire(rxp_in)  enable((*inhigh*)en1) clocked_by(tClock);
    method rxn_wire(rxn_in)  enable((*inhigh*)en0) clocked_by(tClock);
    method txp_out txp_wire  clocked_by(tClock);
    method txn_out txn_wire  clocked_by(tClock);

    method rxp_out rxp_dev() clocked_by(dClock);
    method rxn_out rxn_dev() clocked_by(dClock);
    method txp_dev(txp_in)   enable((*inhigh*)en2) clocked_by(dClock);
    method txn_dev(txn_in)   enable((*inhigh*)en3) clocked_by(dClock);
   
    schedule (txp_dev,txn_dev,rxp_dev,rxn_dev,
              txp_wire,txn_wire,rxp_wire,rxn_wire) CF 
              (txp_dev,txn_dev,rxp_dev,rxn_dev,
              txp_wire,txn_wire,rxp_wire,rxn_wire);
endmodule
