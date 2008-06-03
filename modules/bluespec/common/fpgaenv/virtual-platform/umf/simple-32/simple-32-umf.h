#ifndef __UMF__
#define __UMF__

#include <iostream>

#include "asim/syntax.h"

using namespace std;

#define UMF_CHUNK_BITS      32
#define UMF_CHUNK_BYTES     4
#define UMF_CHUNK_LOG_BYTES 2

// specific types for this UMF implementation
typedef UINT32 UMF_CHUNK;

// ================ UMF Message ================

typedef class UMF_MESSAGE_CLASS* UMF_MESSAGE;
class UMF_MESSAGE_CLASS
{
    private:
        // header info
        UINT32 channelID;
        UINT32 serviceID;
        UINT32 methodID;
        UINT32 length;

        // message
        unsigned char *message;
        int readIndex;
        int writeIndex;

    public:
        // constructors and destructor
        UMF_MESSAGE_CLASS();
        UMF_MESSAGE_CLASS(int len);
        UMF_MESSAGE_CLASS(unsigned char header[]);
        UMF_MESSAGE_CLASS(int cid, int sid, int mid, int len);
        ~UMF_MESSAGE_CLASS();

        // accessors
        int             GetChannelID()  { return channelID; }
        int             GetServiceID()  { return serviceID; }
        int             GetMethodID()   { return methodID;  }
        int             GetLength()     { return length;    }
        unsigned char*  GetMessage()    { return message;   }

        // header modifiers
        void SetChannelID(int cid)   { channelID = cid; }
        void SetServiceID(int sid)   { serviceID = sid; }
        void SetMethodID(int mid)    { methodID  = mid; }

        // other header utilities
        void      DecodeHeaderFromChunk(UMF_CHUNK chunk);
        void      ConstructHeader(unsigned char buf[]);
        UMF_CHUNK ConstructHeader();

        // marshallers
        void AppendBytes(int nbytes, unsigned char data[]);
        void AppendUINT32(UINT32 data);
        void AppendUINT64(UINT64 data);
        void AppendUINT(UINT64 data, int nbytes);
        
        void AppendChunk(UMF_CHUNK chunk);

        // demarshallers
        void   ExtractBytes(int nbytes, unsigned char data[]);
        UINT32 ExtractUINT32();
        UINT64 ExtractUINT64();
        UINT64 ExtractUINT(int nbytes);

        void      StartRead();
        bool      CanRead();
        UMF_CHUNK ReadChunk();

        void      StartReverseRead();
        bool      CanReverseRead();
        UMF_CHUNK ReverseReadChunk();

        // other
        int  BytesRemaining() { return (length - writeIndex); }
        void Print(ostream &out);
};

#endif
