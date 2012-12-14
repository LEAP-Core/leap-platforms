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
