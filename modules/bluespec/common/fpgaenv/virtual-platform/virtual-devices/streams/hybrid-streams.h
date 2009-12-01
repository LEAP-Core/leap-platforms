#ifndef _HYBRID_STREAMS_
#define _HYBRID_STREAMS_

#include "asim/provides/rrr.h"
#include "asim/dict/STREAMS.h"
#include "asim/dict/STREAMID.h"

// constants
const int MAX_STREAMS = (1 << STREAMID_DICT_BITS);

// ===== STREAMS callback module =====
typedef class STREAMS_CALLBACK_MODULE_CLASS* STREAMS_CALLBACK_MODULE;
class STREAMS_CALLBACK_MODULE_CLASS
{
    public:
        virtual void StreamsCallback(UINT32, UINT32, UINT32) = 0;
};

// ===== STREAMS =====
typedef class STREAMS_SERVER_CLASS* STREAMS_SERVER;

class STREAMS_SERVER_CLASS: public RRR_SERVER_CLASS,
                            public PLATFORMS_MODULE_CLASS
{
  private:
    // self-instantiation
    static STREAMS_SERVER_CLASS  instance;
    
    // stubs
    RRR_SERVER_STUB serverStub;

    // per-stream maps
    FILE                    *streamOutput[MAX_STREAMS];
    STREAMS_CALLBACK_MODULE  callbackModule[MAX_STREAMS];
    
    // internal methods
    int CountPayloads(const char *str);
    
  public:
    STREAMS_SERVER_CLASS();
    ~STREAMS_SERVER_CLASS();
    
    // generic RRR methods
    void Init(PLATFORMS_MODULE);
    void Uninit();
    void Cleanup();

    // poll: FIXME FIXME FIXME we need this
    // bool Poll();
    
    // RRR request methods
    void Print(UINT32 streamID, UINT32 stringID, UINT32 payload0, UINT32 payload1);

    // static methods
    static STREAMS_SERVER GetInstance() { return &instance; }
    
    // streams interface
    void MapStream(int, FILE*);
    void RegisterCallback(int, STREAMS_CALLBACK_MODULE);
};

#include "asim/rrr/server_stub_STREAMS.h"

#endif
