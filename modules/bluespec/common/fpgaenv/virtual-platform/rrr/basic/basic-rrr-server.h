#ifndef __BASIC_RRR_SERVER__
#define __BASIC_RRR_SERVER__

#include <stdio.h>

#include "platforms-module.h"
#include "asim/provides/channelio.h"

#define MAX_SERVICES            64

// ============== RRR server base class =================

typedef class RRR_SERVER_CLASS* RRR_SERVER;
class RRR_SERVER_CLASS
{
  public:
    virtual void        Init(PLATFORMS_MODULE) = 0;
    virtual void        Poll(void) {};    
};

// ============== RRR server stub base class =================

typedef class RRR_SERVER_STUB_CLASS* RRR_SERVER_STUB;
class RRR_SERVER_STUB_CLASS
{
  public:
    virtual UMF_MESSAGE Request(UMF_MESSAGE)   = 0;
    virtual void        Init(PLATFORMS_MODULE) = 0;
    virtual void        Poll(void)             = 0;
};

// ================== Basic RRR Server Monitor ==================

typedef class RRR_SERVER_MONITOR_CLASS* RRR_SERVER_MONITOR;
class RRR_SERVER_MONITOR_CLASS: public PLATFORMS_MODULE_CLASS,
                                public CIO_DELIVERY_STATION_CLASS
{
  private:
    
    // static service table
    static RRR_SERVER_STUB ServerMap[MAX_SERVICES];
    
    // maintain a valid-mask for services that have properly
    // registered themselves. We do this because it is possible
    // to explicitly intialize a simple integer static variable
    // to 0, but not an entire array.
    static UINT64 RegistrationMask;
    
    // link to lower layer in protocol stack
    CHANNELIO channelio;
    
    // internal methods
    static inline bool isServerRegistered(int serviceid);
    static inline void setServerRegistered(int serviceid);
    static inline void unsetServerRegistered(int serviceid);
    
  public:

    // static methods used to populate service table
    static void RegisterServer(int serviceid, RRR_SERVER_STUB server_stub);
    
    // regular methods
    RRR_SERVER_MONITOR_CLASS(PLATFORMS_MODULE, CHANNELIO);
    ~RRR_SERVER_MONITOR_CLASS();
    void    Init();
    void    Uninit();
    void    Poll();
    void    DeliverMessage(UMF_MESSAGE msg);
};

#endif
