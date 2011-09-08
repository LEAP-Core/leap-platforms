/*****************************************************************************
 *
 * @file pcie_wrapper.bsv
 * @brief Wrapper for PCIe DMA controller
 *
 * @author rfadeev
 * @mailto roman.fadeev@intel.com
 *
 * Copyright (C) 2011 Intel Corporation
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 *****************************************************************************/

// ****** Bluespec imports ******

import Clocks::*;

// ****** Project imports ******

`include "physical_platform_utils.bsh"
`include "umf.bsh"

// ****** Interfaces ******

(* always_ready, always_enabled *)
interface PCIE_EXP#(numeric type lanes);
    interface Clock       pcie_fake_clk;//isn't used as port or pin, introduced just for correct compilation
    method    Action      pcie_clk_p(Bit#(1) i);
    method    Action      pcie_clk_n(Bit#(1) i);
    method    Action      pcie_reset_n(Bit#(1) i);
    method    Action      rxp(Bit#(lanes) i);
    method    Action      rxn(Bit#(lanes) i);
    method    Bit#(lanes) txp;
    method    Bit#(lanes) txn;
endinterface: PCIE_EXP

interface PCIE_CLK_DEV;
    interface Clock pcie_clk;
    interface Reset pcie_rst;
endinterface

interface PCIE_DRIVER;
    method ActionValue#(UMF_CHUNK) read();
    method Action write(UMF_CHUNK chunk);
endinterface

interface VPCIE_Controller;
    method    Bool             soft_reset();
    interface PCIE_EXP#(8)     pcie_pins;
    interface PCIE_DRIVER      pcie_driver;
    interface PCIE_CLK_DEV     pcie_clk_device;
endinterface

interface PCIE_Controller;
    interface PCIE_EXP#(8)     pcie_pins;
    interface PCIE_DRIVER      pcie_driver;
    interface PCIE_CLK_DEV     pcie_clk_device;
endinterface

// ****** Modules ******

// vmkPCIEWrapper

import "BVI" pcie_dma_device =
module vmkPCIEWrapper#(Clock model_clk, Reset model_rst)(VPCIE_Controller);

    default_clock no_clock;
    default_reset no_reset;

    input_clock (model_clk) = model_clk;
    input_reset (model_rst_n) = model_rst;


    interface PCIE_CLK_DEV pcie_clk_device;
	output_clock pcie_clk(pcie_clk);
	output_reset pcie_rst(pcie_rst_n) clocked_by(pcie_clk_device_pcie_clk);
    endinterface

    
    method SOFT_reset          soft_reset();

    interface PCIE_EXP pcie_pins;
        output_clock           pcie_fake_clk(pcie_fake_clk);
        method                 pcie_clk_p(pcie_clk_p)        enable((*inhigh*)unused0) clocked_by(pcie_pins_pcie_fake_clk) reset_by(no_reset);
        method                 pcie_clk_n(pcie_clk_n)        enable((*inhigh*)unused1) clocked_by(pcie_pins_pcie_fake_clk) reset_by(no_reset);
        method                 pcie_reset_n(pcie_reset_n)    enable((*inhigh*)unused2) clocked_by(pcie_pins_pcie_fake_clk) reset_by(no_reset);
        method                 rxp(rx_p)                     enable((*inhigh*)unused3) clocked_by(pcie_pins_pcie_fake_clk) reset_by(no_reset);
        method                 rxn(rx_n)                     enable((*inhigh*)unused4) clocked_by(pcie_pins_pcie_fake_clk) reset_by(no_reset);
        method    tx_p         txp                                                     clocked_by(no_clock)                reset_by(no_reset);
        method    tx_n         txn                                                     clocked_by(no_clock)                reset_by(no_reset);
    endinterface


    interface PCIE_DRIVER pcie_driver;
        method    DATA_read    read()            enable(EN_read)  ready(RDY_read)  clocked_by(pcie_clk_device_pcie_clk);
        method                 write(DATA_write) enable(EN_write) ready(RDY_write) clocked_by(pcie_clk_device_pcie_clk);
    endinterface

    schedule (pcie_pins_pcie_clk_p, pcie_pins_pcie_clk_n, pcie_pins_pcie_reset_n, pcie_pins_rxp, pcie_pins_rxn, pcie_pins_txp, pcie_pins_txn, soft_reset) CF
             (pcie_pins_pcie_clk_p, pcie_pins_pcie_clk_n, pcie_pins_pcie_reset_n, pcie_pins_rxp, pcie_pins_rxn, pcie_pins_txp, pcie_pins_txn, pcie_driver_write, pcie_driver_read, soft_reset);

    schedule (pcie_driver_read)  CF (pcie_driver_read);
    schedule (pcie_driver_read)  CF (pcie_driver_write);
    schedule (pcie_driver_write) CF (pcie_driver_write);

endmodule: vmkPCIEWrapper

// mkPCIEWrapper

module mkPCIEWrapper#(SOFT_RESET_TRIGGER softResetTrigger, Clock model_clk, Reset model_rst)(PCIE_Controller);

    let v_pcie_dma_dev <- vmkPCIEWrapper(model_clk, model_rst);

    rule proceed_soft_reset(v_pcie_dma_dev.soft_reset());
        softResetTrigger.reset();
    endrule

    return interface PCIE_Controller
               interface pcie_pins   = v_pcie_dma_dev.pcie_pins;
               interface pcie_driver = v_pcie_dma_dev.pcie_driver;
	       interface pcie_clk_device= v_pcie_dma_dev.pcie_clk_device;
           endinterface;

endmodule: mkPCIEWrapper
