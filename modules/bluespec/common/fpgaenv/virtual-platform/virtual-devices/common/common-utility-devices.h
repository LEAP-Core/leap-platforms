//
// @file common-utility-devices.h
// @brief Instantiate useful utility devices.
//
// @author Michael Adler
//

#include <stdio.h>

#include "asim/provides/dynamic_parameters_device.h"

typedef class COMMON_UTILITY_DEVICES_CLASS* COMMON_UTILITY_DEVICES;

class COMMON_UTILITY_DEVICES_CLASS
{
  private:
 
    // The parameter controller is a pure client
    // so we must instantiate it.
    DYNAMIC_PARAMS_DEVICE dynamicParamsDevice;

  public:
    COMMON_UTILITY_DEVICES_CLASS();
    ~COMMON_UTILITY_DEVICES_CLASS();

    void Init();
};

