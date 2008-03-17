#ifndef __UNIX_PIPE__
#define __UNIX_PIPE__

#include "main.h"
#include "asim/provides/umf.h"

#define STDIN             0
#define STDOUT            1
#define DESC_HOST_2_FPGA  100
#define DESC_FPGA_2_HOST  101
#define BLOCK_SIZE        4
#define SELECT_TIMEOUT    1000

// ============================================
//           UNIX Pipe Physical Device
// ============================================
typedef class UNIX_PIPE_DEVICE_CLASS* UNIX_PIPE_DEVICE;
class UNIX_PIPE_DEVICE_CLASS: public HASIM_MODULE_CLASS
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

    public:
        UNIX_PIPE_DEVICE_CLASS(HASIM_MODULE);
        ~UNIX_PIPE_DEVICE_CLASS();

        void Uninit();                     // uninit
        bool Probe();                      // probe for data
        void Read(unsigned char*, int);    // blocking read
        void Write(unsigned char*, int);   // write
};

#endif
