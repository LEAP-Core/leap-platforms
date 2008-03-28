
typedef Bit#(`UMF_CHUNK_BITS)       UMF_CHUNK;

typedef Bit#(`UMF_CHANNEL_ID_BITS)  UMF_CHANNEL_ID;
typedef Bit#(`UMF_SERVICE_ID_BITS)  UMF_SERVICE_ID;
typedef Bit#(`UMF_METHOD_ID_BITS)   UMF_METHOD_ID;
typedef Bit#(`UMF_MSG_LENGTH_BITS)  UMF_MSG_LENGTH;

typedef union tagged
{
    struct
    {
        UMF_CHANNEL_ID  channelID;
        UMF_SERVICE_ID  serviceID;
        UMF_METHOD_ID   methodID;
        UMF_MSG_LENGTH  numChunks;
    }
    UMF_PACKET_header;

    UMF_CHUNK   UMF_PACKET_dataChunk;

} UMF_PACKET
    deriving (Bits);
