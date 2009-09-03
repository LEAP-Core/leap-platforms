#include "asim/rrr/service_ids.h"

#include "asim/provides/common_utility_devices.h"
#include "asim/provides/stats_device.h"

using namespace std;

// constructor
COMMON_UTILITY_DEVICES_CLASS::COMMON_UTILITY_DEVICES_CLASS() :
    dynamicParamsDevice(new DYNAMIC_PARAMS_DEVICE_CLASS())
{
}

// destructor
COMMON_UTILITY_DEVICES_CLASS::~COMMON_UTILITY_DEVICES_CLASS()
{
}

// init
void
COMMON_UTILITY_DEVICES_CLASS::Init()
{
    // Tell the dynamic parameters IO service to send all
    // parameters to the hardware.
    
    dynamicParamsDevice->SendAllParams();
    
    // Tell the stats device to setup itself. We wait until this
    // point to do it to ensure that the RRR stack is up.
    STATS_DEVICE_CLASS::GetInstance()->SetupStats();
}
