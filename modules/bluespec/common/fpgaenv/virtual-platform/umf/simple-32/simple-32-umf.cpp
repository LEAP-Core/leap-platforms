#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <iomanip>

#include "asim/provides/umf.h"

using namespace std;

// constructors
UMF_MESSAGE_CLASS::UMF_MESSAGE_CLASS()
{
    length     = 0;
    readIndex  = 0;
    writeIndex = 0;
    message    = NULL;
}

UMF_MESSAGE_CLASS::UMF_MESSAGE_CLASS(
    int len)
{
    length = len;

    // allocate space for message
    message = new unsigned char[length];

    // init
    readIndex = 0;
    writeIndex = 0;
}

UMF_MESSAGE_CLASS::UMF_MESSAGE_CLASS(
    unsigned char header[])
{
    channelID =  header[3] >> 4;
    serviceID = (header[3] << 4) | (header[2] >> 4);
    methodID  =  header[2] & 0x0F;

    // note: length in encoded header is in terms of number of chunks
    length = UMF_CHUNK_BYTES * ((int(header[1]) << 8) + header[0]);

    // allocate space for message
    message = new unsigned char[length];

    // init
    readIndex = 0;
    writeIndex = 0;
}

UMF_MESSAGE_CLASS::UMF_MESSAGE_CLASS(
    int cid,
    int sid,
    int mid,
    int len)
{
    channelID = cid;
    serviceID = sid;
    methodID  = mid;
    length    = len;

    // allocate space for message
    message = new unsigned char[length];

    // init
    readIndex = 0;
    writeIndex = 0;
}

// destructor
UMF_MESSAGE_CLASS::~UMF_MESSAGE_CLASS()
{
    if (message)
    {
        delete [] message;
    }
}

// construct a header string
void
UMF_MESSAGE_CLASS::ConstructHeader(
    unsigned char buf[])
{
    // convert length to number of chunks
    int num_chunks = (length % UMF_CHUNK_BYTES) == 0     ?
                         (length / UMF_CHUNK_BYTES)      :
                         (length / UMF_CHUNK_BYTES) + 1;
    buf[0] = (unsigned char) (num_chunks & 0x000000FF);
    buf[1] = (unsigned char) (num_chunks >> 8);
    buf[2] = (unsigned char) (serviceID << 4) |
             (unsigned char) (methodID);
    buf[3] = (unsigned char) (channelID << 4) |
             (unsigned char) (serviceID >> 4);
}

// construct a header chunk
UMF_CHUNK
UMF_MESSAGE_CLASS::ConstructHeader()
{
    UMF_CHUNK chunk;

    // convert length to number of chunks
    unsigned int num_chunks = (length % UMF_CHUNK_BYTES) == 0 ?
                              (length / UMF_CHUNK_BYTES)      :
                              (length / UMF_CHUNK_BYTES) + 1;

    chunk = (channelID << 28) |
            (serviceID << 20) |
            (methodID  << 16) |
            num_chunks;

    return chunk;
}

// decode header from chunk
void
UMF_MESSAGE_CLASS::DecodeHeaderFromChunk(
    UMF_CHUNK chunk)
{
    channelID =  chunk >> 28;
    serviceID = (chunk << 4) >> 24;
    methodID  = (chunk << 12) >> 28;

    // note: length in encoded header is in terms of number of chunks
    length = UMF_CHUNK_BYTES * ((chunk << 16) >> 16);

    // allocate space for message
    message = new unsigned char[length];
}

// marshallers
void
UMF_MESSAGE_CLASS::AppendBytes(
    int nbytes,
    unsigned char data[])
{
    assert(message);
    
    if ((writeIndex + nbytes) > length)
    {
        cerr << "umf: messsage write overflow" << endl;
        exit(1);
    }

    memcpy(&message[writeIndex], data, nbytes);
    writeIndex += nbytes;
}

void
UMF_MESSAGE_CLASS::AppendUINT32(
    UINT32 data)
{
    assert(message);

    if ((writeIndex + sizeof(UINT32)) > length)
    {
        cerr << "umf: messsage write overflow" << endl;
        exit(1);
    }

    // convert UINT32 into byte sequence in an endian-agnostic manner
    UINT32 mask = 0xFF;
    int i;
    for (i = 0; i < sizeof(UINT32); i++)
    {
        message[writeIndex++] = (unsigned char)((mask & data) >> (i * 8));
        mask = mask << 8;
    }
}

void
UMF_MESSAGE_CLASS::AppendUINT64(
    UINT64 data)
{
    assert(message);

    if ((writeIndex + sizeof(UINT64)) > length)
    {
        cerr << "umf: messsage write overflow" << endl;
        exit(1);
    }

    // convert UINT64 into byte sequence in an endian-agnostic manner
    UINT64 mask = 0xFF;
    int i;
    for (i = 0; i < sizeof(UINT64); i++)
    {
        message[writeIndex++] = (unsigned char)((mask & data) >> (i * 8));
        mask = mask << 8;
    }
}

void
UMF_MESSAGE_CLASS::AppendChunk(
    UMF_CHUNK chunk)
{
    assert(message);

    if ((writeIndex + sizeof(UMF_CHUNK)) > length)
    {
        cerr << "umf: messsage write overflow" << endl;
        exit(1);
    }

    // convert UMF_CHUNK into byte sequence in an endian-agnostic manner
    UMF_CHUNK mask = 0xFF;
    int i;
    for (i = 0; i < sizeof(UMF_CHUNK); i++)
    {
        message[writeIndex++] = (unsigned char)((mask & chunk) >> (i * 8));
        mask = mask << 8;
    }
}

// demarshallers
void
UMF_MESSAGE_CLASS::ExtractBytes(
    int nbytes,
    unsigned char data[])
{
    assert(message);

    if ((readIndex + nbytes) > writeIndex)
    {
        cerr << "umf: message read underflow: readIndex = "
             << readIndex << " writeIndex = " << writeIndex
             << " nbytes = " << nbytes << endl;
        Print(cerr);
        exit(1);
    }

    if (writeIndex != length)
    {
        cerr << "umf: [WARNING] attempt to read from incomplete "
             << "message, are you sure you want to do this?" << endl;
        // do not exit
    }

    memcpy(data, &message[readIndex], nbytes);
    readIndex += nbytes;
}

UINT32
UMF_MESSAGE_CLASS::ExtractUINT32()
{
    assert(message);

    if ((readIndex + sizeof(UINT32)) > writeIndex)
    {
        cerr << "umf: message read underflow: readIndex = "
             << readIndex << " writeIndex = " << writeIndex
             << " UINT32" << endl;
        Print(cerr);
        exit(1);
    }

    if (writeIndex != length)
    {
        cerr << "umf: [WARNING] attempt to read from incomplete "
             << "message, are you sure you want to do this?" << endl;
        // do not exit
    }

    // extract a UINT32 from the byte sequence in an endian-agnostic manner
    UINT32 retval = 0;
    for (int i = 0; i < sizeof(UINT32); i++)
    {
        UINT32 byte = (UINT32)(message[readIndex++]);
        retval |= (byte << (i * 8));
    }

    return retval;
}

UINT64
UMF_MESSAGE_CLASS::ExtractUINT64()
{
    assert(message);

    if ((readIndex + sizeof(UINT64)) > writeIndex)
    {
        cerr << "umf: message read underflow: readIndex = "
             << readIndex << " writeIndex = " << writeIndex
             << " UINT64" << endl;
        Print(cerr);
        exit(1);
    }

    if (writeIndex != length)
    {
        cerr << "umf: [WARNING] attempt to read from incomplete "
             << "message, are you sure you want to do this?" << endl;
        // do not exit
    }

    // extract a UINT64 from the byte sequence in an endian-agnostic manner
    UINT64 retval = 0;
    for (int i = 0; i < sizeof(UINT64); i++)
    {
        UINT64 byte = (UINT64)(message[readIndex++]);
        retval |= (byte << (i * 8));
    }

    return retval;
}

void
UMF_MESSAGE_CLASS::StartRead()
{
    readIndex = 0;
}

bool
UMF_MESSAGE_CLASS::CanRead()
{
    return(readIndex < writeIndex);
}

UMF_CHUNK
UMF_MESSAGE_CLASS::ReadChunk()
{
    assert(message);

    if ((readIndex + sizeof(UMF_CHUNK)) > writeIndex)
    {
        cerr << "umf: message read underflow: readIndex = "
             << readIndex << " writeIndex = " << writeIndex
             << " UMF_CHUNK" << endl;
        Print(cerr);
        exit(1);
    }

    if (writeIndex != length)
    {
        cerr << "umf: [WARNING] attempt to read from incomplete "
             << "message, are you sure you want to do this?" << endl;
        // do not exit
    }

    // extract a UMF_CHUNK from the byte sequence in an endian-agnostic manner
    UMF_CHUNK retval = 0;
    for (int i = 0; i < sizeof(UMF_CHUNK); i++)
    {
        UMF_CHUNK byte = (UMF_CHUNK)(message[readIndex++]);
        retval |= (byte << (i * 8));
    }

    return retval;
}

// print message to an output stream
void
UMF_MESSAGE_CLASS::Print(
    ostream &out)
{
    out << "channelID: " << channelID << endl;
    out << "serviceID: " << serviceID << endl;
    out << "methodID : " << methodID  << endl;
    out << "length   : " << length    << endl;
    out << "data     : ";

    for (int i = 0; i < length; i++)
    {
        out << setfill('0');
        out << hex << message[i] << " ";
    }
    out << dec << endl;
}
