#include "asim/provides/physical_platform.h"

PHYSICAL_DEVICES_CLASS::PHYSICAL_DEVICES_CLASS(
    HASIM_MODULE p) :
        HASIM_MODULE_CLASS(p),
        pciExpressDevice(this)
{
}

PHYSICAL_DEVICES_CLASS::~PHYSICAL_DEVICES_CLASS()
{
}
