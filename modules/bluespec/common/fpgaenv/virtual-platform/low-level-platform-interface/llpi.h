#ifndef __LLPI__
#define __LLPI__

#include "platforms-module.h"
#include "asim/provides/physical_platform.h"
#include "asim/provides/channelio.h"
#include "asim/provides/rrr.h"

// Low Level Platform Interface

// A convenient bundle of all ways to interact with the outside world.
typedef class LLPI_CLASS* LLPI;
class LLPI_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:
    // LLPI stack layers
    PHYSICAL_DEVICES_CLASS   physicalDevices;
    CHANNELIO_CLASS          channelio;
    RRR_CLIENT_CLASS         rrrClient;
    RRR_SERVER_MONITOR_CLASS rrrServer;

  public:
    // constructor - destructor
    LLPI_CLASS();
    ~LLPI_CLASS();

    // Main
    void Main();
    
    // accessors
    PHYSICAL_DEVICES   GetPhysicalDevices() { return &physicalDevices; }
    CHANNELIO          GetChannelIO()       { return &channelio; }
    RRR_CLIENT         GetRRRClient()       { return &rrrClient; }
    RRR_SERVER_MONITOR GetRRRServer()       { return &rrrServer; }

    // poll
    void Poll();
};

#endif
