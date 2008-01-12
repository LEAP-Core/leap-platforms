#ifndef __PHYSICAL_CHANNEL__
#define __PHYSICAL_CHANNEL__

#include "umf.h"

#define STDIN                   0
#define STDOUT                  1
#define CHANNELIO_HOST_2_FPGA   100
#define CHANNELIO_FPGA_2_HOST   101

#define BLOCK_SIZE      4

#define SELECT_TIMEOUT  1000

// ============================================
//               Physical Channel              
// ============================================

class PHYSICAL_CHANNEL_CLASS
{
    private:
        // process/pipe state (physical channel)
        int  inpipe[2], outpipe[2];
        int  childpid;
        bool childAlive;

        #define PARENT_READ     inpipe[0]
        #define CHILD_WRITE     inpipe[1]
        #define CHILD_READ      outpipe[0]
        #define PARENT_WRITE    outpipe[1]
        
        // incomplete incoming read message
        UMF_MESSAGE     incomingMessage;

        // internal methods
        bool        dataAvailableOnPipe();
        void        readPipe();

    public:
        PHYSICAL_CHANNEL_CLASS();
        ~PHYSICAL_CHANNEL_CLASS();
        void        Uninit();

        UMF_MESSAGE Read();             // blocking read
        UMF_MESSAGE TryRead();          // non-blocking read
        void        Write(UMF_MESSAGE); // write
};

#endif
