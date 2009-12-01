
//
// @file dynamic-parameters.h
// @brief Pass dynamic parameters to the hardware side
//
// @author Michael Adler
//

#ifndef _PARAMS_CONTROLLER_
#define _PARAMS_CONTROLLER_

#include <stdio.h>

#include "platforms-module.h"
#include "asim/provides/rrr.h"
#include "asim/rrr/client_stub_PARAMS.h"

typedef class DYNAMIC_PARAMS_DEVICE_CLASS* DYNAMIC_PARAMS_DEVICE;

class DYNAMIC_PARAMS_DEVICE_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:
 
    // stub
    PARAMS_CLIENT_STUB clientStub;

  public:
    DYNAMIC_PARAMS_DEVICE_CLASS();
    ~DYNAMIC_PARAMS_DEVICE_CLASS();

    // Send dynamic parameters to hardware
    void SendAllParams();

    // required RRR service methods
    void Init(PLATFORMS_MODULE);
    void Uninit();
    void Cleanup();
};


#endif
