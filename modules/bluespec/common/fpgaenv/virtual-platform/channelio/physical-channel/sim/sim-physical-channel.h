#ifndef __PHYSICAL_CHANNEL__
#define __PHYSICAL_CHANNEL__

#include "asim/provides/umf.h"
#include "asim/provides/physical_platform.h"

// ============================================
//               Physical Channel              
// ============================================

class PHYSICAL_CHANNEL_CLASS: public HASIM_MODULE_CLASS
{
    private:
        // cached links to useful physical devices
        UNIX_PIPE_DEVICE unixPipeDevice;

        // incomplete incoming read message
        UMF_MESSAGE incomingMessage;

        // internal methods
        void readPipe();

    public:
        PHYSICAL_CHANNEL_CLASS(HASIM_MODULE, PHYSICAL_DEVICES);
        ~PHYSICAL_CHANNEL_CLASS();

        UMF_MESSAGE Read();             // blocking read
        UMF_MESSAGE TryRead();          // non-blocking read
        void        Write(UMF_MESSAGE); // write
};

#endif
