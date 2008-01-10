#ifndef __UMF__
#define __UMF__

#define UMF_CHUNK_BITS      32
#define UMF_CHUNK_BYTES     4
#define UMF_CHUNK_LOG_BYTES 2

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
        // constructors and destructor
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
        void    SetChannelID(int cid)   { channelID = cid; }
        void    SetServiceID(int sid)   { serviceID = sid; }
        void    SetMethodID(int mid)    { methodID  = mid; }

        // marshallers
        void AppendBytes(int nbytes, unsigned char data[]);
        void AppendUINT32(UINT32 data);
        void AppendUINT64(UINT64 data);

        // demarshallers
        void   ExtractBytes(int nbytes, unsigned char data[]);
        UINT32 ExtractUINT32();
        UINT64 ExtractUINT64();

        // other
        void ConstructHeader(unsigned char buf[]);
        int  BytesRemaining() { return (length - writeIndex); }
};

#endif
