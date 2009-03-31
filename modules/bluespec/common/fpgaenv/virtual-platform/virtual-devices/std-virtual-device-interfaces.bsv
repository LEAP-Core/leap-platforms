//
// Copyright (C) 2009 Intel Corporation
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
// Common definition of the interfaces to virtual devices.
//

import Vector::*;

`include "asim/provides/librl_bsv_base.bsh"

// ========================================================================
//
// Scratchpad memory
//
// ========================================================================

`include "asim/dict/VDEV.bsh"

//
// Compute the clients of scratchpad memory.  Clients register by adding entries
// to the VDEV.SCRATCH dictionary.
//

`ifndef VDEV_SCRATCH__NENTRIES
// No clients.
`define VDEV_SCRATCH__NENTRIES 0
`endif

typedef `VDEV_SCRATCH__NENTRIES SCRATCHPAD_N_CLIENTS;

//
// Interface to a single scratchpad port.  By having separate ports defined
// for each scratchpad, instead of adding a port argument to the methods,
// this module is capable of defining the relative priority of the ports.
//
interface SCRATCHPAD_MEMORY_PORT#(type t_ADDR, type t_DATA);
    interface MEMORY_IFC#(t_ADDR, t_DATA) mem;

    // Initialize a port, requesting an allocation of allocLastWordIdx + 1
    // SCRATCHPAD_MEM_VALUE sized words.
    method ActionValue#(Bool) init(t_ADDR allocLastWordIdx);
endinterface: SCRATCHPAD_MEMORY_PORT

//
// A scratchpad interface has one memory interface for each client.  Using
// a vector of MEMORY_IFCs instead of adding a port parameter to a
// MEMORY_IFC-like interface makes the scratchpad interchangeable with
// other memories in the clients.
//
interface SCRATCHPAD_MEMORY_VIRTUAL_DEVICE#(type t_ADDR, type t_DATA);
    interface Vector#(SCRATCHPAD_N_CLIENTS, SCRATCHPAD_MEMORY_PORT#(t_ADDR, t_DATA)) ports;
endinterface: SCRATCHPAD_MEMORY_VIRTUAL_DEVICE
