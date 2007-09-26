#ifndef __SOFTWARE_RRR_SERVER__
#define __SOFTWARE_RRR_SERVER__

#include "main.h"
#include "sim-channelio-sw.h"

#define MAX_SERVICES            128
#define MAX_ARGS                3

// forward definition of RRR server class pointer
typedef class RRR_SERVER_CLASS* RRR_SERVER;

// *************** RRR service base class ***************
typedef class RRR_SERVICE_CLASS* RRR_SERVICE;
class RRR_SERVICE_CLASS
{
    protected:
        int             serviceID;  // unique service ID

    public:
        virtual void    Init(HASIM_SW_MODULE, int)                  = 0;
        virtual void    Uninit()                                    = 0;
        virtual bool    Request(UINT32, UINT32, UINT32, UINT32 *)   = 0;
        virtual void    Poll(void)                                  = 0;
};


// ***************** software RRR server *****************

// main server class
// typedef class RRR_SERVER_CLASS* RRR_SERVER;
class RRR_SERVER_CLASS: public HASIM_SW_MODULE_CLASS
{
    private:
        RRR_SERVICE     ServiceMap[MAX_SERVICES];
        int             n_services;
        CHANNELIO       channelio;

        // internal methods
        void    unpack(UINT32, unsigned char[]);
        UINT32  pack(unsigned char[]);

    public:
        RRR_SERVER_CLASS(HASIM_SW_MODULE, CHANNELIO);
        ~RRR_SERVER_CLASS();
        void    Init();
        void    Uninit();
        void    Poll();
};

#endif
