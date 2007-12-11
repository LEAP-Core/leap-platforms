#ifndef __UMF__
#define __UMF__

#define UMF_CHUNK_BITS      32
#define UMF_CHUNK_BYTES     4
#define UMF_CHUNK_LOG_BYTES 2

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

#endif
