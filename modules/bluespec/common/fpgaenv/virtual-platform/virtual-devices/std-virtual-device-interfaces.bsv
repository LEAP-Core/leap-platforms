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
// Scratchpad port number.  Add 1 to the number of clients in case there is
// only one client.  Bit#(0) is not a valid array index.
//
typedef Bit#(TLog#(TAdd#(1, SCRATCHPAD_N_CLIENTS))) SCRATCHPAD_PORT_NUM;

//
// Scratpads are not required to return read results in order.  Clients
// are expected to use the SCRATCHPAD_CLIENT_REF_INFO type to tag read requests
// with information to route them correctly.
//
typedef `SCRATCHPAD_CLIENT_REF_INFO_BITS SCRATCHPAD_CLIENT_REF_INFO_SZ;
typedef Bit#(SCRATCHPAD_CLIENT_REF_INFO_SZ) SCRATCHPAD_CLIENT_REF_INFO;

//
// Scratchpad reference ID.  Used for directing requests to the right
// ports and reordering cache reads.
//
typedef struct
{
    SCRATCHPAD_PORT_NUM portNum;
    SCRATCHPAD_CLIENT_REF_INFO clientRefInfo;
}
SCRATCHPAD_REF_INFO
    deriving (Eq, Bits);

//
// Scratchpad read response returns metadata along with the value.  The
// refInfo field contains tags to direct the response to the correct port
// and to sort responses chronologically.  (The scratchpad memory may return
// results out of order due to cache effects.)
//
// The address of the value is returned because some clients with private
// caches need the address to insert the value into a cache.  Returning
// the address eliminates the need for private FIFOs in the clients to track
// addresses.
//
typedef struct
{
    t_DATA val;
    t_ADDR addr;
    SCRATCHPAD_REF_INFO refInfo;
}
SCRATCHPAD_READ_RESP#(type t_ADDR, type t_DATA)
    deriving (Eq, Bits);


//
// All scratchpad requests flow through a single request/response interface.
// The platform interface module may fan out connections to clients of the
// scratchpad using, for example, multiple soft connections.
//
// The REF_INFO is used to determine address spaces and route reponses back
// to the corresponding requester.
//
interface SCRATCHPAD_MEMORY_VIRTUAL_DEVICE#(type t_ADDR, type t_DATA);
    method Action readReq(t_ADDR addr, SCRATCHPAD_REF_INFO refInfo);
    method ActionValue#(SCRATCHPAD_READ_RESP#(t_ADDR, t_DATA)) readRsp();
 
    method Action write(t_ADDR addr, t_DATA val, SCRATCHPAD_PORT_NUM portNum);

    // Initialize a port, requesting an allocation of allocLastWordIdx + 1
    // SCRATCHPAD_MEM_VALUE sized words.
    method ActionValue#(Bool) init(t_ADDR allocLastWordIdx, SCRATCHPAD_PORT_NUM portNum);
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
// Central cache port number.  Add 1 to the number of clients in case there is
// only one client.  Bit#(0) is not a valid array index.
//
typedef Bit#(TLog#(TAdd#(1, CENTRAL_CACHE_N_CLIENTS))) CENTRAL_CACHE_PORT_NUM;

//
// Standard basic types for all central cache implementations
//

// Word-based address
typedef Bit#(`CENTRAL_CACHE_LINE_ADDR_BITS) CENTRAL_CACHE_LINE_ADDR;

// Cache line & word sizes match the local memory
typedef LOCAL_MEM_LINE CENTRAL_CACHE_LINE;
typedef LOCAL_MEM_WORD CENTRAL_CACHE_WORD;
typedef LOCAL_MEM_WORDS_PER_LINE CENTRAL_CACHE_WORDS_PER_LINE;

typedef Bit#(TLog#(CENTRAL_CACHE_WORDS_PER_LINE)) CENTRAL_CACHE_WORD_IDX;


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


//
// Central cache requests
//

typedef struct
{
    CENTRAL_CACHE_LINE_ADDR addr;
    CENTRAL_CACHE_WORD_IDX wordIdx;
    CENTRAL_CACHE_REF_INFO refInfo;
}
CENTRAL_CACHE_READ_REQ
    deriving (Eq, Bits);

// Write a word to a cache line.  Word index 0 corresponds to the
// low bits of a cache line.
typedef struct
{
    CENTRAL_CACHE_LINE_ADDR addr;
    CENTRAL_CACHE_WORD_IDX wordIdx;
    CENTRAL_CACHE_WORD val;
    CENTRAL_CACHE_REF_INFO refInfo;
}
CENTRAL_CACHE_WRITE_REQ
    deriving (Eq, Bits);

// Invalidate & flush requests.  Both write dirty lines back.  Invalidate drops
// the line from the cache.  Flush keeps the line in the cache.  A response
// is returned for invalOrFlushWait iff sendAck is true.
typedef struct
{
    CENTRAL_CACHE_LINE_ADDR addr;
    Bool sendAck;
    CENTRAL_CACHE_REF_INFO refInfo;
}
CENTRAL_CACHE_INVAL_REQ
    deriving (Eq, Bits);

typedef union tagged
{
    CENTRAL_CACHE_READ_REQ  CENTRAL_CACHE_READ;
    CENTRAL_CACHE_WRITE_REQ CENTRAL_CACHE_WRITE;
    CENTRAL_CACHE_INVAL_REQ CENTRAL_CACHE_INVAL;
    CENTRAL_CACHE_INVAL_REQ CENTRAL_CACHE_FLUSH;
}
CENTRAL_CACHE_REQ
    deriving (Eq, Bits);


// Cache read response
typedef RL_SA_CACHE_LOAD_RESP#(CENTRAL_CACHE_LINE_ADDR,
                               CENTRAL_CACHE_WORD,
                               CENTRAL_CACHE_WORDS_PER_LINE,
                               CENTRAL_CACHE_REF_INFO) CENTRAL_CACHE_READ_LINE_RESP;

//
// Interface to each central cache client.
//
interface CENTRAL_CACHE_CLIENT_PORT;

    method Action newReq(CENTRAL_CACHE_REQ req);

    // Respond with up to a full line.  Read from backing store if not
    // already cached.  The read response is guaranteed to return at least
    // the requested word in the line.  If more of the line is already
    // available it will be returned as well.
    method ActionValue#(CENTRAL_CACHE_READ_LINE_RESP) readResp();

    method Action invalOrFlushWait();

endinterface: CENTRAL_CACHE_CLIENT_PORT


//
// Backing storage read request
//
typedef struct
{
    CENTRAL_CACHE_LINE_ADDR addr;
    CENTRAL_CACHE_REF_INFO refInfo;
}
CENTRAL_CACHE_BACKING_READ_REQ
    deriving (Eq, Bits);

//
// Backing storage write request.  A write request has two phases:  control
// and data.  This request is the control phase.
//
typedef struct
{
    CENTRAL_CACHE_LINE_ADDR addr;
    Vector#(CENTRAL_CACHE_WORDS_PER_LINE, Bool) wordValidMask;
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
    // Read request and response with data.  The read response is pipelined.
    // For every getReadReq there must be one sendReadResp for every word in
    // the requested line.  Low bits of the line are received first.
    method ActionValue#(CENTRAL_CACHE_BACKING_READ_REQ) getReadReq();
    method Action sendReadResp(CENTRAL_CACHE_WORD val);
    
    // Write to backing storage.  A write begins with a write request.
    // It is followed by multiple write data calls, one call per word
    // in a cache line.
    method ActionValue#(CENTRAL_CACHE_BACKING_WRITE_REQ) getWriteReq();

    // Called multiple times after a write request is received -- once for
    // each word in a line.  THIS METHOD MUST BE CALLED FOR A WORD EVEN
    // IF THE CONTROL INFORMATION SAYS THE WORD IS NOT VALID.  Low bits
    // of the line are sent first.
    method ActionValue#(CENTRAL_CACHE_WORD) getWriteData();

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

    method Action init(RL_SA_CACHE_MODE mode);
endinterface: CENTRAL_CACHE_VIRTUAL_DEVICE
