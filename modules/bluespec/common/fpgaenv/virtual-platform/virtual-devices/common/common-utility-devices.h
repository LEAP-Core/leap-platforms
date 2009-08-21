
//
// @file dynamic-parameters.h
// @brief Pass dynamic parameters to the hardware side
//
// @author Michael Adler
//

#ifndef _IO_SERVICES_
#define _IO_SERVICES_

#include <stdio.h>

#include "asim/provides/dynamic_parameters_io.h"

typedef class COMMON_UTILITY_DEVICES_CLASS* COMMON_UTILITY_DEVICES;

class COMMON_UTILITY_DEVICES_CLASS
{
  private:
 
    // The parameter controller is a pure client
    // so we must instantiate it.
    DYNAMIC_PARAMS_IO dynamicParamsIO;

  public:
    COMMON_UTILITY_DEVICES_CLASS();
    ~COMMON_UTILITY_DEVICES_CLASS();

    void Init();
};


#endif
