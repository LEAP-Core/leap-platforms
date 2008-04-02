#include "asim/provides/physical_platform.h"

PHYSICAL_DEVICES_CLASS::PHYSICAL_DEVICES_CLASS(
    HASIM_MODULE p) :
        HASIM_MODULE_CLASS(p)
{
}

PHYSICAL_DEVICES_CLASS::~PHYSICAL_DEVICES_CLASS()
{
    Uninit();
}

void
PHYSICAL_DEVICES_CLASS::Uninit()
{
    pciExpressDevice.Uninit();
}
