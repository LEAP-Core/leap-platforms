#ifndef __HYBRID_MEMORY__
#define __HYBRID_MEMORY__

#include "software-rrr-server.h"

/* our memory, for now, is a UINT32 aligned array */
#define MEM_SIZE    262144 /* 256K * 4 = 1MB memory size */
#define CMD_LOAD    0
#define CMD_STORE   1

class MEMORY_CLASS: public RRR_SERVICE_CLASS,
                    public HASIM_SW_MODULE_CLASS
{
    private:
        UINT32* M;
        bool    vmhLoaded;

    public:
        MEMORY_CLASS();
        ~MEMORY_CLASS();
        void    Init(HASIM_SW_MODULE, int);
        void    Uninit();
        bool    Request(UINT32, UINT32, UINT32, UINT32 *);
        void    Poll();
};

#endif
