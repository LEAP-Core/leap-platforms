#ifndef __PHYSICAL_PLATFORM__
#define __PHYSICAL_PLATFORM__

#include "asim/provides/unix_pipe_device.h"
#include "main.h"

// ====================================================
//             Simulation Physical Platform
// ====================================================

// This class is a collection of all physical devices
// present on the Simulation Physical Platform
typedef class PHYSICAL_DEVICES_CLASS* PHYSICAL_DEVICES;
class PHYSICAL_DEVICES_CLASS: public HASIM_MODULE_CLASS
{
    private:
        UNIX_PIPE_DEVICE_CLASS unixPipeDevice;

    public:
        // constructor-destructor
        PHYSICAL_DEVICES_CLASS(HASIM_MODULE);
        ~PHYSICAL_DEVICES_CLASS();

        void Uninit();

        // accessors to individual devices
        UNIX_PIPE_DEVICE GetUNIXPipeDevice() { return &unixPipeDevice; }
};

#endif
