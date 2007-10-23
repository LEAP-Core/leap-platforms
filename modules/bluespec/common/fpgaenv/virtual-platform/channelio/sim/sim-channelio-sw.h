#ifndef __SIM_CHANNELIO__
#define __SIM_CHANNELIO__

#include "main.h"

#define CHANNELIO_PACKET_SIZE   4
#define STDIN                   0
#define STDOUT                  1
#define CHANNELIO_HOST_2_FPGA   100
#define CHANNELIO_FPGA_2_HOST   101

// general typedefs
typedef unsigned int UINT32;
typedef unsigned long long UINT64;

// *************** Channel I/O ****************

typedef class CHANNELIO_CLASS* CHANNELIO;

class CHANNELIO_CLASS:  public HASIM_SW_MODULE_CLASS
{
    private:
        // process/pipe state
        int inpipe[2], outpipe[2];
        int childpid;

        #define PARENT_READ     inpipe[0]
        #define CHILD_WRITE     inpipe[1]
        #define CHILD_READ      outpipe[0]
        #define PARENT_WRITE    outpipe[1]

        // internal methods
        void    initHardware();
        void    uninitHardware();

    public:
        CHANNELIO_CLASS(HASIM_SW_MODULE);
        ~CHANNELIO_CLASS();
        void    Init();
        void    Uninit();
        void    Read(unsigned char[]);
        void    Write(unsigned char[]);
        void    Poll();
};

#endif
