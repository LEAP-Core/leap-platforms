#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>

#include "umf.h"

using namespace std;

// constructors
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
    // the following code assumes a 32-bit header
    // and a particular header organization
    channelID =  header[3] >> 4;
    serviceID = (header[3] << 4) | (header[2] >> 4);
    methodID  =  header[2] & 0x0F;

    // note: length in encoded header is in terms
    // of number of chunks
    length    = UMF_CHUNK_BYTES * ((int(header[1]) << 8) + header[0]);

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

// marshallers
void
UMF_MESSAGE_CLASS::AppendBytes(
    int nbytes,
    unsigned char data[])
{
    assert(message);
    
    if ((writeIndex + nbytes) > length)
    {
        cerr << "channelio-sw: messsage write overflow" << endl;
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
        cerr << "channelio-sw: messsage write overflow" << endl;
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
        cerr << "channelio-sw: messsage write overflow" << endl;
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

// demarshallers
void
UMF_MESSAGE_CLASS::ExtractBytes(
    int nbytes,
    unsigned char data[])
{
    assert(message);

    if ((readIndex + nbytes) > writeIndex)
    {
        cerr << "channelio-sw: message read underflow: readIndex = "
             << readIndex << " writeIndex = " << writeIndex
             << " nbytes = " << nbytes << endl;
        exit(1);
    }

    if (writeIndex != length)
    {
        cerr << "channelio-sw: [WARNING] attempt to read from incomplete "
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
        cerr << "channelio-sw: message read underflow: readIndex = "
             << readIndex << " writeIndex = " << writeIndex
             << " UINT32" << endl;
        exit(1);
    }

    if (writeIndex != length)
    {
        cerr << "channelio-sw: [WARNING] attempt to read from incomplete "
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
        cerr << "channelio-sw: message read underflow: readIndex = "
             << readIndex << " writeIndex = " << writeIndex
             << " UINT64" << endl;
        exit(1);
    }

    if (writeIndex != length)
    {
        cerr << "channelio-sw: [WARNING] attempt to read from incomplete "
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
