#include "asim/provides/physical_platform.h"

PHYSICAL_DEVICES_CLASS::PHYSICAL_DEVICES_CLASS(
    PLATFORMS_MODULE p) :
        PLATFORMS_MODULE_CLASS(p),
        unixPipeDevice(this)
{
}

PHYSICAL_DEVICES_CLASS::~PHYSICAL_DEVICES_CLASS()
{
}
