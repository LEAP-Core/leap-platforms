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
`include "asim/provides/librl_bsv_cache.bsh"
`include "asim/provides/local_mem.bsh"

`include "asim/dict/VDEV.bsh"


// ========================================================================
//
// Scratchpad memory
//
// ========================================================================

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



// ========================================================================
//
// Central cache
//
// ========================================================================

//
// Compute the clients of the central cache.  Clients register by adding
// entries to the VDEV.CACHE dictionary.
//

`ifndef VDEV_CACHE__NENTRIES
// No clients.
`define VDEV_CACHE__NENTRIES 0
`endif

typedef `VDEV_CACHE__NENTRIES CENTRAL_CACHE_N_CLIENTS;

//
// Standard basic types for all central cache implementations
//
typedef Bit#(`CENTRAL_CACHE_ADDR_BITS) CENTRAL_CACHE_ADDR;

// Cache line & word sizes match the local memory
typedef LOCAL_MEM_LINE CENTRAL_CACHE_LINE;
typedef LOCAL_MEM_WORD CENTRAL_CACHE_WORD;
typedef LOCAL_MEM_WORDS_PER_LINE CENTRAL_CACHE_WORDS_PER_LINE;


// Reference info is a private metadata structure passed to the cache with a
// request.  The data is returned along with a response and forwarded to the
// backing storage requests generated as side effects of any requests.  The
// reference info may hold context ID or anything else needed by the client.
//
// The central cache is constructed before any of the clients, so the
// reference info type here is necessarily generic.  The only requirement
// is that the reference info type here must be at least as big as
// the largest required by all clients.
//
typedef Bit#(`CENTRAL_CACHE_REFINFO_BITS) CENTRAL_CACHE_REF_INFO;

// Cache read response
typedef RL_SA_CACHE_LOAD_RESP#(CENTRAL_CACHE_ADDR,
                               CENTRAL_CACHE_WORD,
                               CENTRAL_CACHE_WORDS_PER_LINE,
                               CENTRAL_CACHE_REF_INFO) CENTRAL_CACHE_READ_RESP;


//
// Interface to a single central cache client port.
//
interface CENTRAL_CACHE_CLIENT_PORT;

    // Read up to a full line.  Read from backing store if not already cached.
    // The read response is guaranteed to return at least the requested
    // word in the line.  If more of the line is already available it will
    // be returned as well.
    method Action readReq(CENTRAL_CACHE_ADDR addr,
                          Bit#(TLog#(CENTRAL_CACHE_WORDS_PER_LINE)) wordIdx,
                          CENTRAL_CACHE_REF_INFO refInfo);

    method ActionValue#(CENTRAL_CACHE_READ_RESP) readResp();


    // Write a word to a cache line.  Word index 0 corresponds to the
    // low bits of a cache line.
    method Action write(CENTRAL_CACHE_ADDR addr,
                        CENTRAL_CACHE_WORD val,
                        Bit#(TLog#(CENTRAL_CACHE_WORDS_PER_LINE)) wordIdx,
                        CENTRAL_CACHE_REF_INFO refInfo);
    
    // Invalidate & flush requests.  Both write dirty lines back.  Invalidate drops
    // the line from the cache.  Flush keeps the line in the cache.  A response
    // is returned for invalOrFlushWait iff sendAck is true.
    method Action invalReq(CENTRAL_CACHE_ADDR addr, Bool sendAck, CENTRAL_CACHE_REF_INFO refInfo);
    method Action flushReq(CENTRAL_CACHE_ADDR addr, Bool sendAck, CENTRAL_CACHE_REF_INFO refInfo);
    method Action invalOrFlushWait();

endinterface: CENTRAL_CACHE_CLIENT_PORT


//
// Backing storage read request
//
typedef struct
{
    CENTRAL_CACHE_ADDR addr;
    CENTRAL_CACHE_REF_INFO refInfo;
}
CENTRAL_CACHE_BACKING_READ_REQ
    deriving (Eq, Bits);

//
// Backing storage write request
//
typedef struct
{
    CENTRAL_CACHE_ADDR addr;
    Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) wordValidMask;
    CENTRAL_CACHE_LINE val;
    CENTRAL_CACHE_REF_INFO refInfo;
    Bool sendAck;
}
CENTRAL_CACHE_BACKING_WRITE_REQ
    deriving (Eq, Bits);


//
// Backing storage port specification.  The backing storage port really wants
// a server from which to make requests, but that would cause a loop
// during static elaboration between the client of the cache and the server
// of the storage.  Instead, the backing storage port here is a polled interface.
// The cache client is expected to poll the backing storage port methods and
// respond to requests for backing storage I/O.
//
interface CENTRAL_CACHE_BACKING_PORT;
    // Read request and response with data
    method ActionValue#(CENTRAL_CACHE_BACKING_READ_REQ) getReadReq();
    method Action sendReadResp(CENTRAL_CACHE_LINE val);
    
    // Write to backing storage.
    method ActionValue#(CENTRAL_CACHE_BACKING_WRITE_REQ) getWriteReq();
    // Ack from write request when sendAck is True
    method Action sendWriteAck();
endinterface: CENTRAL_CACHE_BACKING_PORT


//
// Each central cache client must communicate on two ports.  The client
// port handles requests from the clients.  The backing storage port
// communicates with the backing storage associated with the port and
// is used to handle fills and spills.
//
interface CENTRAL_CACHE_VIRTUAL_DEVICE;
    interface Vector#(CENTRAL_CACHE_N_CLIENTS,
                      CENTRAL_CACHE_CLIENT_PORT) clientPorts;

    interface Vector#(CENTRAL_CACHE_N_CLIENTS,
                      CENTRAL_CACHE_BACKING_PORT) backingPorts;

    method Action init(Bool enableCache, Bool cacheIsWriteBack);
endinterface: CENTRAL_CACHE_VIRTUAL_DEVICE
