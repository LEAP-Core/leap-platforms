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
    message = new unsigned char[UMF_MAX_MSG_BYTES];
    Clear();
}

// destructor
UMF_MESSAGE_CLASS::~UMF_MESSAGE_CLASS()
{
    delete [] message;
}

// init
void
UMF_MESSAGE_CLASS::Init(
    PLATFORMS_MODULE p)
{
    parent = p;
}

// clear all message data
void
UMF_MESSAGE_CLASS::Clear()
{
    length     = 0;
    readIndex  = 0;
    writeIndex = 0;
}

// allocate a new message: pipe through to the allocator
UMF_MESSAGE
UMF_MESSAGE_CLASS::New()
{
    // ask allocator to give us a new message
    UMF_MESSAGE retval = UMF_ALLOCATOR_CLASS::GetInstance()->New();

    // optional: initialize
    retval->Clear();

    return retval;
}

// de-allocate this message: pipe through to the allocator
void
UMF_MESSAGE_CLASS::Delete()
{
    // ask allocator to de-allocate me
    UMF_ALLOCATOR_CLASS::GetInstance()->Delete(this);
}
//
// marshallers: most of these are trivial for little-endian machines
//

void
UMF_MESSAGE_CLASS::StartAppend()
{
    writeIndex = 0;
}

bool
UMF_MESSAGE_CLASS::CanAppend()
{
    return(writeIndex < length);
}

void
UMF_MESSAGE_CLASS::AppendBytes(
    int nbytes,
    unsigned char data[])
{
    assert(message);
    
    if ((writeIndex + nbytes) > length)
    {
        cerr << "umf: message write overflow" << endl;
        CallbackExit(1);
    }

    memcpy(&message[writeIndex], data, nbytes);
    writeIndex += nbytes;
}

void
UMF_MESSAGE_CLASS::AppendUINT8(
    UINT8 data)
{
    AppendBytes(sizeof(UINT8), (unsigned char*) &data);
}

void
UMF_MESSAGE_CLASS::AppendUINT32(
    UINT32 data)
{
    AppendBytes(sizeof(UINT32), (unsigned char*) &data);
}

void
UMF_MESSAGE_CLASS::AppendUINT64(
    UINT64 data)
{
    AppendBytes(sizeof(UINT64), (unsigned char*) &data);
}

void
UMF_MESSAGE_CLASS::AppendUINT(
    UINT64 data,
    int nbytes)
{
    if (nbytes > 8)
    {
        cerr << "umf: AppendUINT can take 8 bytes maximum" << endl;
        CallbackExit(1);
    }

    AppendBytes(nbytes, (unsigned char*) &data);
}

void
UMF_MESSAGE_CLASS::AppendChunk(
    UMF_CHUNK chunk)
{
    AppendBytes(sizeof(UMF_CHUNK), (unsigned char*) &chunk);
}

void
UMF_MESSAGE_CLASS::AppendChunks(
    int nchunks,
    UMF_CHUNK chunks[])
{
    AppendBytes(nchunks * sizeof(UMF_CHUNK), (unsigned char*) chunks);
}

//
// demarshallers
//

void
UMF_MESSAGE_CLASS::StartExtract()
{
    readIndex = 0;
}

bool
UMF_MESSAGE_CLASS::CanExtract()
{
    return(readIndex < writeIndex);
}

void
UMF_MESSAGE_CLASS::CheckExtractSanity(
    int nbytes)
{
    assert(message);

    if ((readIndex + nbytes) > writeIndex)
    {
        cerr << "umf: message read underflow: readIndex = "
             << readIndex << " writeIndex = " << writeIndex
             << " nbytes = " << nbytes << endl;
        Print(cerr);
        CallbackExit(1);
    }

    if (writeIndex != length)
    {
        cerr << "umf: [WARNING] attempt to read from incomplete "
             << "message, are you sure you want to do this?" << endl;
        // do not exit
    }
}

void
UMF_MESSAGE_CLASS::ExtractBytes(
    int nbytes,
    unsigned char data[])
{
    CheckExtractSanity(nbytes);
    memcpy(data, &message[readIndex], nbytes);
    readIndex += nbytes;
}

UINT8
UMF_MESSAGE_CLASS::ExtractUINT8()
{
    CheckExtractSanity(sizeof(UINT8));
    UINT8 retval = *(UINT8 *)(&message[readIndex]);
    readIndex += sizeof(UINT8);
    return retval;
}

UINT32
UMF_MESSAGE_CLASS::ExtractUINT32()
{
    CheckExtractSanity(sizeof(UINT32));
    UINT32 retval = *(UINT32 *)(&message[readIndex]);
    readIndex += sizeof(UINT32);
    return retval;
}

UINT64
UMF_MESSAGE_CLASS::ExtractUINT64()
{
    CheckExtractSanity(sizeof(UINT64));
    UINT64 retval = *(UINT64 *)(&message[readIndex]);
    readIndex += sizeof(UINT64);
    return retval;
}

UINT64
UMF_MESSAGE_CLASS::ExtractUINT(
    int nbytes)
{
    if (nbytes > sizeof(UINT64))
    {
        cerr << "umf: ExtractUINT can take 8 bytes maximum" << endl;
        CallbackExit(1);
    }

    // it's too risky to do a direct typecast here
    CheckExtractSanity(nbytes);
    UINT64 retval = 0;
    memcpy((unsigned char*)&retval, &message[readIndex], nbytes);
    readIndex += nbytes;
    return retval;
}

UMF_CHUNK
UMF_MESSAGE_CLASS::ExtractChunk()
{
    CheckExtractSanity(sizeof(UMF_CHUNK));
    UMF_CHUNK retval = *(UMF_CHUNK *)(&message[readIndex]);
    readIndex += sizeof(UMF_CHUNK);
    return retval;
}

//
// reverse (MSByte -> LSByte) read methods
//

void
UMF_MESSAGE_CLASS::StartReverseExtract()
{
    readIndex = length;
}

bool
UMF_MESSAGE_CLASS::CanReverseExtract()
{
    return(readIndex > 0);
}

UMF_CHUNK
UMF_MESSAGE_CLASS::ReverseExtractChunk()
{
    assert(message);

    // if readIndex = i, we want to read bytes (i - CHUNK_SIZE) .. (i - 1)

    if (writeIndex != length)
    {
        cerr << "umf: [WARNING] attempt to reverse-read from incomplete "
             << "message, are you sure you want to do this?" << endl;
        // do not exit
    }

    // SPECIAL CASE: if this is the first reverse-read in a sequence, and
    //               the message length is not a multiple of UMF_CHUNK size,
    //               then pad this chunk
    if ((readIndex % sizeof(UMF_CHUNK)) != 0)
    {
        // sanity: this MUST be the first read
        ASSERTX(readIndex == length);

        // pad and read out the data
        UMF_CHUNK retval = 0;
        UINT32 residue = readIndex % sizeof(UMF_CHUNK);
        readIndex -= residue;
        memcpy(&retval, &message[readIndex], residue);
        return retval;
    }
    else
    {
        // copy the data behind the pointer and retard the pointer
        readIndex -= sizeof(UMF_CHUNK);
        return *(UMF_CHUNK *)(&message[readIndex]);
    }
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
        out << std::setfill('0');
        out << hex << std::setw(2) << UINT32(message[i]) << " ";
    }
    out << dec << endl;
}
