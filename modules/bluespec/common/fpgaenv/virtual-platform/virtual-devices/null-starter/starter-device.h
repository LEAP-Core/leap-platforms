#ifndef _STARTER_
#define _STARTER_

#include <stdio.h>
#include <sys/time.h>
#include <pthread.h>

#include "asim/provides/low_level_platform_interface.h"
#include "asim/provides/starter_device.h"
#include "asim/provides/model.h"


// this module provides both client and server functionalities


//
// STARTER_SERVER_CLASS --
//
//

typedef class STARTER_DEVICE_SERVER_CLASS* STARTER_DEVICE_SERVER;

class STARTER_DEVICE_SERVER_CLASS: public RRR_SERVER_CLASS,
                            public PLATFORMS_MODULE_CLASS

{

  public:
    STARTER_DEVICE_SERVER_CLASS();
    ~STARTER_DEVICE_SERVER_CLASS();

    // static methods
    static STARTER_DEVICE_SERVER GetInstance() { return NULL; }

    // required RRR methods
    void Init(PLATFORMS_MODULE);
    void Uninit();
    void Cleanup();

    //
    // RRR server methods
    //
    void End(UINT8 success);
    void Heartbeat(UINT64 fpga_cycles);

    // client methods
    void Start();
  

};

// our STARTER_DEVICE_SERVER class is itself the main STARTER class
typedef STARTER_DEVICE_SERVER_CLASS STARTER_DEVICE_CLASS;

#endif
