#ifndef __BASIC_RRR_SERVER__
#define __BASIC_RRR_SERVER__

#include <stdio.h>

#include "main.h"
#include "sim-channelio.h"

#define MAX_SERVICES            64
#define MAX_ARGS                3

// ============== RRR service base class =================
typedef class RRR_SERVICE_CLASS* RRR_SERVICE;
class RRR_SERVICE_CLASS
{
    protected:
        int             serviceID;  // unique service ID

    public:
        virtual void    Init(HASIM_MODULE)                          = 0;
        virtual void    Uninit()                                    = 0;
        virtual bool    Request(UINT32, UINT32, UINT32, UINT32 *)   = 0;
        virtual void    Poll(void)                                  = 0;
};


// ================== Basic RRR server ==================

// main server class
typedef class RRR_SERVER_CLASS* RRR_SERVER;
class RRR_SERVER_CLASS: public HASIM_MODULE_CLASS,
                        public CIO_DELIVERY_STATION_CLASS
{
    private:

        // static service table
        static RRR_SERVICE  ServiceMap[MAX_SERVICES];

        // maintain a valid-mask for services that have properly
        // registered themselves. We do this because it is possible
        // to explicitly intialize a simple integer static variable
        // to 0, but not an entire array.
        static UINT64       ServiceValidMask;

        // link to lower layer in protocol stack
        CHANNELIO           channelio;

        // internal methods
        void    unpack(UINT32, unsigned char[]);
        UINT32  pack(unsigned char[]);

        static inline bool isServiceValid(int serviceid);
        static inline void setServiceValid(int serviceid);
        static inline void unsetServiceValid(int serviceid);

    public:
        // static methods used to populate service table
        static void RegisterService(int serviceid, RRR_SERVICE service);

        // regular methods
        RRR_SERVER_CLASS(HASIM_MODULE, CHANNELIO);
        ~RRR_SERVER_CLASS();
        void    Init();
        void    Uninit();
        void    Poll();
        void    DeliverMessage(UMF_MESSAGE msg);
};

#endif
