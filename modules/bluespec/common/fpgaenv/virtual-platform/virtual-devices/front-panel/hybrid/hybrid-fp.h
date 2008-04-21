#ifndef __HYBRID_FRONT_PANEL__
#define __HYBRID_FRONT_PANEL__

#include "asim/provides/rrr.h"

#define SELECT_TIMEOUT      1000
#define DIALOG_PACKET_SIZE  4
#define STDIN               0
#define STDOUT              1

class FRONT_PANEL_CLASS:    public RRR_SERVICE_CLASS,
                            public PLATFORMS_MODULE_CLASS
{
    private:
        // self-instantiation
        static FRONT_PANEL_CLASS    instance;

        // other data
        int     dialogpid;
        int     child_to_parent[2];
        int     parent_to_child[2];

        UINT32  inputCache;
        bool    inputDirty;
        UINT32  outputCache;
        bool    outputDirty;

        bool    childAlive;

        // internal methods
        void    syncInputs();
        void    syncOutputs();

    public:
        FRONT_PANEL_CLASS();
        ~FRONT_PANEL_CLASS();

        void        Init(PLATFORMS_MODULE);
        void        Uninit();
        void        Cleanup();
        // bool     Request(UINT32, UINT32, UINT32, UINT32, UINT32 *);
        UMF_MESSAGE Request(UMF_MESSAGE);
        void        Poll();
};

#endif
