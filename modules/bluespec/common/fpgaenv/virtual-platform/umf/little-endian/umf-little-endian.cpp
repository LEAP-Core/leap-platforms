/*****************************************************************************
 * umf-little-endian.cpp
 *
 * Copyright (C) 2008 Intel Corporation
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

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
