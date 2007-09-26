#ifndef __HYBRID_FRONT_PANEL__
#define __HYBRID_FRONT_PANEL__

#include "software-rrr-server.h"

#define SELECT_TIMEOUT      1000
#define DIALOG_PACKET_SIZE  4
#define STDIN               0
#define STDOUT              1

class FRONT_PANEL_CLASS:    public RRR_SERVICE_CLASS,
                            public HASIM_SW_MODULE_CLASS
{
    private:
        int     dialogpid;
        int     child_to_parent[2];
        int     parent_to_child[2];

        UINT32  inputCache;
        UINT32  outputCache;
        bool    outputDirty;

        bool    childAlive;

        // internal methods
        void    syncInputs();
        void    syncOutputs();

    public:
        FRONT_PANEL_CLASS();
        ~FRONT_PANEL_CLASS();
        void    Init(HASIM_SW_MODULE, int);
        void    Uninit();
        bool    Request(UINT32, UINT32, UINT32, UINT32 *);
        void    Poll();
};

#endif
