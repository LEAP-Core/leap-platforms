#ifndef __SIM_CHANNELIO__
#define __SIM_CHANNELIO__

#include <queue>
#include "main.h"

using namespace std;

//#define CHANNELIO_PACKET_SIZE   4
#define STDIN                   0
#define STDOUT                  1
#define CHANNELIO_HOST_2_FPGA   100
#define CHANNELIO_FPGA_2_HOST   101

#define BLOCK_SIZE      4
#define MSG_BUFFER_SIZE 4

#define SELECT_TIMEOUT  1000

// the following defines will be generated from the .awb
// file once hasim-configure starts generating C++ headers
#define CIO_NUM_CHANNELS    2
#define CIO_CHUNK_BITS      32
#define CIO_CHUNK_BYTES     4
#define CIO_CHUNK_LOG_BYTES 2

// general typedefs
typedef unsigned int UINT32;
typedef unsigned long long UINT64;

// ================ UMF Message ================

typedef class UMF_MESSAGE_CLASS* UMF_MESSAGE;
class UMF_MESSAGE_CLASS
{
    private:
        // header info
        int channelID;
        int serviceID;
        int methodID;
        int length;

        // message
        unsigned char *message;
        int readIndex;
        int writeIndex;

    public:
        // constructor/destructor
        UMF_MESSAGE_CLASS(unsigned char header[]);
        UMF_MESSAGE_CLASS(int cid, int sid, int mid, int len);
        ~UMF_MESSAGE_CLASS();

        // accessors
        int             GetChannelID()  { return channelID; }
        int             GetServiceID()  { return serviceID; }
        int             GetMethodID()   { return methodID;  }
        int             GetLength()     { return length;    }
        unsigned char*  GetMessage()    { return message;   }

        // message modifiers
        void Append(int nbytes, unsigned char data[]);
        void Extract(int nbytes, unsigned char data[]);

        // other
        void ConstructHeader(unsigned char buf[]);
        int  BytesRemaining() { return (length - writeIndex); }
};


// =============== Channel I/O ================

typedef class CHANNELIO_CLASS* CHANNELIO;
class CHANNELIO_CLASS:  public HASIM_SW_MODULE_CLASS
{
    private:
        // process/pipe state (physical channel)
        int inpipe[2], outpipe[2];
        int childpid;

        #define PARENT_READ     inpipe[0]
        #define CHILD_WRITE     inpipe[1]
        #define CHILD_READ      outpipe[0]
        #define PARENT_WRITE    outpipe[1]

        // buffers
        queue<UMF_MESSAGE>      readBuffer[CIO_NUM_CHANNELS];
        queue<UMF_MESSAGE>      writeBuffer[CIO_NUM_CHANNELS];

        // other state
        UMF_MESSAGE    currentMessage;

        // internal methods
        void    initHardware();
        void    uninitHardware();
        void    syncReadBuffers();
        void    flushWriteBuffer(int channel);

    public:
        CHANNELIO_CLASS(HASIM_SW_MODULE);
        ~CHANNELIO_CLASS();
        void        Init();
        void        Uninit();
        UMF_MESSAGE Read(int channel);
        void        Write(int channel, UMF_MESSAGE message);
        void        Poll();
};

#endif
