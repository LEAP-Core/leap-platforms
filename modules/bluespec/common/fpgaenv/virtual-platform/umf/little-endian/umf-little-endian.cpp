//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

/**
 * @file umf-little-endian.cpp
 * @author Angshuman Parashar
 * @brief UMF implementation
 */

//
// Little-endian UMF
//

#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <iomanip>

#include "asim/provides/umf.h"

using namespace std;

// decode header from chunk
void
UMF_MESSAGE_CLASS::DecodeHeader(
    UMF_CHUNK chunk)
{
    header = chunk;

    // note: length in encoded header is in terms of number of chunks
    length = UMF_CHUNK_BYTES * (chunk & UMF_MSG_LENGTH_MASK);
    chunk >>= UMF_MSG_LENGTH_BITS;

    methodID  = chunk & UMF_METHOD_ID_MASK;
    chunk >>= UMF_METHOD_ID_BITS;

    serviceID = chunk & UMF_SERVICE_ID_MASK;
    chunk >>= UMF_SERVICE_ID_BITS;

    channelID = chunk & UMF_CHANNEL_ID_MASK;

    phyPvt = chunk >> UMF_CHANNEL_ID_BITS;

    if (length > UMF_MAX_MSG_BYTES)
    {
        cerr << "umf: message size too long: " << length << endl;
        CallbackExit(1);
    }
}

UMF_CHUNK
UMF_MESSAGE_CLASS::GetHeader()
{
    return header;
}


// encode a header chunk from my internal info
UMF_CHUNK UMF_MESSAGE_CLASS::EncodeHeaderWithPhyChannelPvt(unsigned int pvt)
{
    UMF_CHUNK chunk;

    // convert length to number of chunks
    unsigned int num_chunks = (length % UMF_CHUNK_BYTES) == 0 ?
                              (length / UMF_CHUNK_BYTES)      :
                              (length / UMF_CHUNK_BYTES) + 1;


    chunk = pvt;

    chunk <<= UMF_CHANNEL_ID_BITS;
    chunk |= channelID;

    chunk <<= UMF_SERVICE_ID_BITS;
    chunk |= serviceID;

    chunk <<= UMF_METHOD_ID_BITS;
    chunk |= methodID;

    chunk <<= UMF_MSG_LENGTH_BITS;
    chunk |= num_chunks;

    return chunk;
}


UMF_CHUNK
UMF_MESSAGE_CLASS::EncodeHeader() 
{
    return EncodeHeaderWithPhyChannelPvt(0);
}


//
// Char array based header encode/decode.  Both routines depend on the machine
// being little endian and headers being 32 bits.
//
void UMF_MESSAGE_CLASS::DecodeHeader(
    unsigned char header[])
{
    UMF_CHUNK chunk = *(UINT32 *) header;
    DecodeHeader(chunk);
}


void
UMF_MESSAGE_CLASS::EncodeHeader(
    unsigned char buf[]) 
{
    UMF_CHUNK chunk = EncodeHeader();

    *(UINT32*) buf = chunk;
}

// init
void
UMF_MESSAGE_CLASS::Init(
    PLATFORMS_MODULE p)
{
    parent = p;
}

// allocate a new message: pipe through to the allocator
void *
UMF_MESSAGE_CLASS::operator new(size_t size)
{
    ASSERTX(size == sizeof(UMF_MESSAGE_CLASS));

    // ask allocator to give us a new message
    UMF_MESSAGE retval = UMF_ALLOCATOR_CLASS::GetInstance()->New();

    return retval;
}

// de-allocate this message: pipe through to the allocator
void
UMF_MESSAGE_CLASS::operator delete(void *obj)
{
    // ask allocator to de-allocate me
    UMF_ALLOCATOR_CLASS::GetInstance()->Delete((UMF_MESSAGE)obj);
}


// print message to an output stream
void
UMF_MESSAGE_CLASS::Print(
    ostream &out)
{
    if(UMF_DEBUG)
    {
        return;
    }

    out << "channelID: " << channelID << endl;
    out << "serviceID: " << serviceID << endl;
    out << "methodID : " << methodID  << endl;
    out << "length   : " << length    << endl;

    out << "Header   : ";
    for (int i = 0; i < UMF_CHUNK_BYTES/sizeof(UINT32); i++)
    {
        out << std::setfill('0');
        out << hex << std::setw(2) << UINT32(((UINT32*)&header)[i]) << " ";
    }
    out << endl;

    out << "PhyPvt   : ";
    for (int i = 0; i < UMF_CHUNK_BYTES/sizeof(UINT32); i++)
    {
        out << std::setfill('0');
        out << hex << std::setw(2) << UINT32(((UINT32*)&phyPvt)[i]) << " ";
    }
    out << endl;

    out << "Data     : ";

    for (int i = 0; i < length; i++)
    {
        out << std::setfill('0');
        out << hex << std::setw(2) << UINT32(message[i]) << " ";
    }
    out << dec << endl;
}
