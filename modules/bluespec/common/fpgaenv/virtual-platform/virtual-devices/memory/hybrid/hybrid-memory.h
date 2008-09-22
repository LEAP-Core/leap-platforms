#ifndef __HYBRID_SCRATCHPAD_MEMORY__
#define __HYBRID_SCRATCHPAD_MEMORY__

#include "asim/provides/rrr.h"
#include "asim/rrr/client_stub_SCRATCHPAD_MEMORY.h"

// our memory, for now, is a 1MB UINT32 aligned array
#define MEM_SIZE 262144

typedef class SCRATCHPAD_MEMORY_SERVER_CLASS* SCRATCHPAD_MEMORY_SERVER;

class SCRATCHPAD_MEMORY_SERVER_CLASS: public RRR_SERVER_CLASS,
                           public PLATFORMS_MODULE_CLASS
{
  private:

    // self-instantiation
    static SCRATCHPAD_MEMORY_SERVER_CLASS instance;

    // stubs
    SCRATCHPAD_MEMORY_CLIENT_STUB clientStub;
    RRR_SERVER_STUB               serverStub;

    // internal data
    UINT32* M;
    bool    vmhLoaded;

    // internal methods
    void   LoadVMH();
    UINT32 AlignAddress(UINT32);

  public:

    SCRATCHPAD_MEMORY_SERVER_CLASS();
    ~SCRATCHPAD_MEMORY_SERVER_CLASS();

    // generic RRR methods
    void   Init(PLATFORMS_MODULE);
    void   Uninit();
    void   Cleanup();
    void   Poll();

    // RRR request methods
    UINT32 Load (UINT32);
    void   Store(UINT32 addr, UINT32 val);
};

#include "asim/rrr/server_stub_SCRATCHPAD_MEMORY.h"

#endif
