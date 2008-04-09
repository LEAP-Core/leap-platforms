#include "asim/provides/low_level_platform_interface.h"

LLPI_CLASS::LLPI_CLASS() :
        PLATFORMS_MODULE_CLASS(NULL),
        physicalDevices(this),
        channelio(this, &physicalDevices),
        rrrClient(this, &channelio),
        rrrServer(this, &channelio)
{
    // set global link to RRR client
    // the service modules need this link since they
    // are statically instantiated
    RRRClient = &rrrClient;
}

LLPI_CLASS::~LLPI_CLASS()
{
}

void
LLPI_CLASS::Poll()
{
    // poll channelio and RRR server
    channelio.Poll();
    rrrServer.Poll();
}
