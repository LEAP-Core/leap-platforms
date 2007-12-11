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
    unsigned char header[])
{
    // the following code assumes a 32-bit header
    // and a particular header organization
    channelID =  header[3] >> 4;
    serviceID = (header[3] << 4) | (header[2] >> 4);
    methodID  =  header[2] & 0x0F;
    length    = (int(header[1]) << 8) + header[0];

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
    buf[0] = (unsigned char) (length & 0x000000FF);
    buf[1] = (unsigned char) (length >> 8);
    buf[2] = (unsigned char) (serviceID << 4) |
             (unsigned char) (methodID);
    buf[3] = (unsigned char) (channelID << 4) |
             (unsigned char) (serviceID >> 4);
}

// message modifiers/extractors
void
UMF_MESSAGE_CLASS::Append(
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
UMF_MESSAGE_CLASS::Extract(
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
