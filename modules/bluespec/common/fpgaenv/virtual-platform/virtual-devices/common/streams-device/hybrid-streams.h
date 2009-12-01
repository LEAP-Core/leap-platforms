#ifndef _HYBRID_STREAMS_DEVICE_
#define _HYBRID_STREAMS_DEVICE_

#include "asim/provides/rrr.h"
#include "asim/dict/STREAMS.h"
#include "asim/dict/STREAMID.h"

// constants
const int MAX_STREAMS_DEVICE = (1 << STREAMID_DICT_BITS);

// ===== STREAMS_DEVICE callback module =====
typedef class STREAMS_DEVICE_CALLBACK_MODULE_CLASS* STREAMS_DEVICE_CALLBACK_MODULE;
class STREAMS_DEVICE_CALLBACK_MODULE_CLASS
{
    public:
        virtual void StreamsCallback(UINT32, UINT32, UINT32) = 0;
};

// ===== STREAMS_DEVICE =====
typedef class STREAMS_DEVICE_SERVER_CLASS* STREAMS_DEVICE_SERVER;
typedef class STREAMS_DEVICE_SERVER_CLASS* STREAMS_SERVER;

class STREAMS_DEVICE_SERVER_CLASS: public RRR_SERVER_CLASS,
                            public PLATFORMS_MODULE_CLASS
{
  private:
    // self-instantiation
    static STREAMS_DEVICE_SERVER_CLASS  instance;
    
    // stubs
    RRR_SERVER_STUB serverStub;

    // per-stream maps
    FILE                    *streamOutput[MAX_STREAMS_DEVICE];
    STREAMS_DEVICE_CALLBACK_MODULE  callbackModule[MAX_STREAMS_DEVICE];
    
    // internal methods
    int CountPayloads(const char *str);
    
  public:
    STREAMS_DEVICE_SERVER_CLASS();
    ~STREAMS_DEVICE_SERVER_CLASS();
    
    // generic RRR methods
    void Init(PLATFORMS_MODULE);
    void Uninit();
    void Cleanup();
    
    // RRR request methods
    void Print(UINT32 streamID, UINT32 stringID, UINT32 payload0, UINT32 payload1);

    // static methods
    static STREAMS_DEVICE_SERVER GetInstance() { return &instance; }
    
    // streams interface
    void MapStream(int, FILE*);
    void RegisterCallback(int, STREAMS_DEVICE_CALLBACK_MODULE);
};

#include "asim/rrr/server_stub_STREAMS.h"

#endif
