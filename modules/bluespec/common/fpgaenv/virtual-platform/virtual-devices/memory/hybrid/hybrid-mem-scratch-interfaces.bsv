
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
// Scratchpad port number.  Add 2 to the number of clients in case there are
// zero or one clients.  Bit#(0) is not a valid array index.
//
typedef Bit#(TLog#(TAdd#(2, SCRATCHPAD_N_CLIENTS))) SCRATCHPAD_PORT_NUM;

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
// Debug scan state
//
typedef struct
{
    Bool uncachedReqWritePending;
    Bool uncachedReqReadPending;
    Bool initQnotEmpty;
}
SCRATCHPAD_MEMORY_DEBUG_SCAN
    deriving (Eq, Bits);


//
// All scratchpad requests flow through a single request/response interface.
// The platform interface module may fan out connections to clients of the
// scratchpad using, for example, multiple soft connections.
//
// The REF_INFO is used to determine address spaces and route reponses back
// to the corresponding requester.
//
interface SCRATCHPAD_MEMORY_VIRTUAL_DEVICE#(type t_ADDR, type t_DATA, type t_MASK);
    method Action readReq(t_ADDR addr,
                          t_MASK byteMask,
                          SCRATCHPAD_REF_INFO refInfo);
    method ActionValue#(SCRATCHPAD_READ_RESP#(t_ADDR, t_DATA)) readRsp();
 
    method Action write(t_ADDR addr,
                        t_DATA val,
                        SCRATCHPAD_PORT_NUM portNum);
    method Action writeMasked(t_ADDR addr,
                              t_DATA val,
                              t_MASK byteMask,
                              SCRATCHPAD_PORT_NUM portNum);

    // Initialize a port, requesting an allocation of allocLastWordIdx + 1
    // SCRATCHPAD_MEM_VALUE sized words.
    method ActionValue#(Bool) init(t_ADDR allocLastWordIdx,
                                   SCRATCHPAD_PORT_NUM portNum,
                                   Bool useCentralCache);

    method SCRATCHPAD_MEMORY_DEBUG_SCAN debugScanState();
endinterface: SCRATCHPAD_MEMORY_VIRTUAL_DEVICE

