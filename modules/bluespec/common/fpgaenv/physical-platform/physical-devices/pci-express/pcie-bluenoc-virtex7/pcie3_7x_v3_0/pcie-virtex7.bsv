//
// Copyright (c) 2008- 2009 Bluespec, Inc.  All rights reserved.
// Copyright (c) 2015, Intel Corporation
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
// Expose a Virtex-7 PCIe endpoint as a BlueNoC node.
//

import Clocks::*;
import GetPut::*;
import Connectable::*;
import DefaultValue::*;
import TieOff::*;
import ByteCompactor::*;
import MsgFormat::*;
import ClientServer::*;
import BlueNoC::*;
import XilinxCells::*;
import XilinxPCIE::*;

`include "awb/provides/pcie_bluenoc_ifc.bsh"
`include "awb/provides/pcie_bluenoc_device.bsh"


// ========================================================================
//
//   Synthesized wrappers generate clean boundaries in the Bluespec-
//   generated Verilog, allowing regions to be placed in area groups.
//   Without the synthesis boundary some Bluespec compiler temporary
//   names are difficult to match with a pattern.
//
//   Synthesis boundary interfaces can't be polymorphic.  Hence the
//   specificity of PCIE_BYTES_PER_BEAT in interfaces.
//
// ========================================================================

//
// mkPCIEBlueNoCDevice --
//   Instantiate the PCIe device-specific driver.  The incoming pcieSysClkBuf
//   is the PCIe source clock.
//
(* synthesize *)
module mkPCIEBlueNoCDevice#(Clock pcieSysClkBuf, Reset pcieSysRst)
    // Interface:
    (BNOC_PCIE_DEV#(PCIE_BYTES_PER_BEAT));

    // Instantiate a PCIE endpoint
    PCIEParams pcie_params = defaultValue();
    PCIExpress3V7#(PCIE_LANES) ep <-
        mkPCIExpress3EndpointV7(pcie_params,
                                clocked_by pcieSysClkBuf,
                                reset_by pcieSysRst);

    mkTieOff(ep.cfg_interrupt);

    // The PCIE endpoint is processing TLPWord#(8)s at 250MHz.  The
    // NoC bridge is accepting TLPWord#(16)s at 125 MHz. The
    // connection between the endpoint and the NoC contains GearBox
    // instances for the TLPWord#(8)@250 <--> TLPWord#(16)@125
    // conversion.

    // The PCIe endpoint exports full (250MHz) and half-speed (125MHz) clocks
    Clock epClock250 = ep.uclk;
    Reset epReset250 = ep.ureset;
    Clock epClock125 = ep.uclk_half;
    Reset epReset125 = ep.ureset_half;

    // Extract some status info from the PCIE endpoint. These values are
    // all in the epClock250 domain, so we have to cross them into the
    // epClock125 domain.

    Bool link_is_up = ep.status.lnk_up();
    UInt#(13) max_read_req_bytes_250       = 128 << ep.status.max_read_req;
    UInt#(13) max_payload_bytes_250        = 128 << ep.status.max_payload;
    UInt#(8)  read_completion_boundary_250 = 64 << ep.status.rcb_status[0];
    Bool      msix_enable_250              = (ep.cfg_interrupt_msix.enabled()[0] == 1);
    Bool      msix_masked_250              = (ep.cfg_interrupt_msix.mask()[0]    == 1);

    CrossingReg#(UInt#(13)) max_rd_req_cr  <- mkNullCrossingReg(epClock125, 128,   clocked_by epClock250, reset_by epReset250);
    CrossingReg#(UInt#(13)) max_payload_cr <- mkNullCrossingReg(epClock125, 128,   clocked_by epClock250, reset_by epReset250);
    CrossingReg#(UInt#(8))  rcb_cr         <- mkNullCrossingReg(epClock125, 128,   clocked_by epClock250, reset_by epReset250);
    CrossingReg#(Bool)      msix_enable_cr <- mkNullCrossingReg(epClock125, False, clocked_by epClock250, reset_by epReset250);
    CrossingReg#(Bool)      msix_masked_cr <- mkNullCrossingReg(epClock125, True,  clocked_by epClock250, reset_by epReset250);

    Reg#(UInt#(13)) max_read_req_bytes <- mkReg(128,   clocked_by epClock125, reset_by epReset125);
    Reg#(UInt#(13)) max_payload_bytes  <- mkReg(128,   clocked_by epClock125, reset_by epReset125);
    Reg#(Bit#(7))   rcb_mask           <- mkReg(7'h3f, clocked_by epClock125, reset_by epReset125);
    Reg#(Bool)      msix_enable        <- mkReg(False, clocked_by epClock125, reset_by epReset125);
    Reg#(Bool)      msix_masked        <- mkReg(True,  clocked_by epClock125, reset_by epReset125);

    (* fire_when_enabled, no_implicit_conditions *)
    rule cross_config_values;
        max_rd_req_cr  <= max_read_req_bytes_250;
        max_payload_cr <= max_payload_bytes_250;
        rcb_cr         <= read_completion_boundary_250;
        msix_enable_cr <= msix_enable_250;
        msix_masked_cr <= msix_masked_250;
    endrule

    (* fire_when_enabled, no_implicit_conditions *)
    rule register_config_values;
        max_read_req_bytes <= max_rd_req_cr.crossed();
        max_payload_bytes  <= max_payload_cr.crossed();
        rcb_mask           <= (rcb_cr.crossed() == 64) ? 7'h3f : 7'h7f;
        msix_enable        <= msix_enable_cr.crossed();
        msix_masked        <= msix_masked_cr.crossed();
    endrule

    CrossingReg#(Bool) intr_on <- mkNullCrossingReg( epClock125, False, clocked_by epClock250, reset_by epReset250 );

    // setup PCIe interrupt for MSI-X
    // this rule executes in the epClock250 domain
    (* fire_when_enabled, no_implicit_conditions *)
    rule intr_ifc_ctl;
        // tie off the unused portion of the MSI-X interface
        ep.cfg_interrupt_msix.valid(0);
        ep.cfg_interrupt_msix.address(0);
        ep.cfg_interrupt_msix.data(0);

        intr_on <= msix_enable_cr && (ep.status.function_status()[2] == 1);
    endrule: intr_ifc_ctl

    // Instantiate the TLP-to-BNoC bridge and connect the PCIe endpoint to it.
    PCIE3toBNoC#(PCIE_BYTES_PER_BEAT) bridge <-
        mkBNoCBridgeSynth(64'hc001_1eaf_c0de_d00d,
                          max_read_req_bytes,
                          max_payload_bytes,
                          rcb_mask,
                          msix_enable,
                          msix_masked,
                          False, // use MSI-X, not MSI
                          clocked_by epClock125, reset_by epReset125);

    // Connect the BlueNoC bridge to the PCIe device.
    mkConnectionWithClocks (ep.cq_recv, bridge.cq_tlps,
                            epClock250, epReset250, epClock125, epReset125);
    mkConnectionWithClocks (ep.cc_xmit, bridge.cc_tlps,
                            epClock250, epReset250, epClock125, epReset125);

    mkConnectionWithClocks (ep.rq_xmit, bridge.rq_tlps,
                            epClock250, epReset250, epClock125, epReset125);
    mkConnectionWithClocks (ep.rc_recv, bridge.rc_tlps,
                            epClock250, epReset250, epClock125, epReset125);

    // Create a reset for the NoC design which incorporates soft reset through
    // the bridge.
    MakeResetIfc soft_reset <- mkReset(16, True,
                                       epClock125, clocked_by epClock125,
                                       reset_by epReset125);

    (* fire_when_enabled, no_implicit_conditions *)
    rule do_soft_reset if (! bridge.is_activated());
        soft_reset.assertReset();
    endrule


    interface PCIE_LOW_LEVEL_DRIVER driver;
        interface MsgPort noc = bridge.noc;

        interface Clock clock = epClock125;
        interface Reset reset = soft_reset.new_rst;
    endinterface

    // FPGA pin interface
    interface PCIE_EXP pcie_exp = ep.pcie;
      
endmodule


(* synthesize *)
module mkBNoCBridgeSynth#(Bit#(64)  board_content_id,
                          UInt#(13) max_read_req_bytes,
                          UInt#(13) max_payload_bytes,
                          Bit#(7)   rcb_mask,
                          Bool      msix_enabled,
                          Bool      msix_mask_all_intr,
                          Bool      msi_enabled)
    // Interface:
    (PCIE3toBNoC#(PCIE_BYTES_PER_BEAT));

    let bridge <- mkPCIE3toBNoC(board_content_id,
                                max_read_req_bytes,
                                max_payload_bytes,
                                rcb_mask,
                                msix_enabled,
                                msix_mask_all_intr,
                                msi_enabled);
    return bridge;
endmodule
