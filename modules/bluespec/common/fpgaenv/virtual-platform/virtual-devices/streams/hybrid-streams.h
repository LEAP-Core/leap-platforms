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
typedef class STREAMS_CLASS* STREAMS;
class STREAMS_CLASS: public RRR_SERVICE_CLASS,
                     public HASIM_MODULE_CLASS
{
    private:
        // self-instantiation
        static STREAMS_CLASS  instance;

        // per-stream maps
        FILE                    *streamOutput[MAX_STREAMS];
        STREAMS_CALLBACK_MODULE  callbackModule[MAX_STREAMS];

        // internal methods
        int CountPayloads(const char *str);

    public:
        STREAMS_CLASS();
        ~STREAMS_CLASS();

        // generic RRR methods
        void  Init(HASIM_MODULE);
        void  Uninit();
        bool  Request(UINT32, UINT32, UINT32, UINT32, UINT32 *);
        void  Poll();

        // static methods
        static STREAMS   GetInstance() { return &instance; }

        // streams interface
        void MapStream(int, FILE*);
        void RegisterCallback(int, STREAMS_CALLBACK_MODULE);
};

#endif
