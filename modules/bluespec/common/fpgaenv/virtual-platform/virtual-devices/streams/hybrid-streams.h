#ifndef _HYBRID_STREAMS_
#define _HYBRID_STREAMS_

#include "asim/provides/rrr.h"

typedef class STREAMS_CLASS* STREAMS;
class STREAMS_CLASS: public RRR_SERVICE_CLASS,
                     public HASIM_MODULE_CLASS
{
    private:
        // self-instantiation
        static STREAMS_CLASS  instance;

        FILE*   eventfile;
        FILE*   statfile;

    public:
        STREAMS_CLASS();
        ~STREAMS_CLASS();

        // generic RRR methods
        void    Init(HASIM_MODULE);
        void    Uninit();
        bool    Request(UINT32, UINT32, UINT32, UINT32, UINT32 *);
        void    Poll();

        // static methods
        static STREAMS   GetInstance() { return &instance; }

        // printer methods
        void PrintMessage(UINT32, UINT32, UINT32);
        void PrintEvent(UINT32, UINT32, UINT32);
        void PrintStat(UINT32, UINT32);
        void PrintAssert(UINT32, UINT32);
        void PrintMemTestReq(UINT32, UINT32, UINT32);
};

#endif
