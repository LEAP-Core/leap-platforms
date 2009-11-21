/*****************************************************************************
 * umf-little-endian.h
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
 * @file umf-little-endian.h
 * @author Angshuman Parashar
 * @brief UMF interface
 */

//
// Little-endian UMF
//

#ifndef __UMF__
#define __UMF__

#include <iostream>

#include "asim/syntax.h"

#include "asim/provides/umf.h"
#include "platforms-module.h"

using namespace std;

// specific types for this UMF implementation
#if (UMF_CHUNK_BYTES == 4)
typedef UINT32 UMF_CHUNK;
#elif (UMF_CHUNK_BYTES == 8)
typedef UINT64 UMF_CHUNK;
#else
#error Unsupported UMF_CHUNK_BYTES
#endif

// Bit masks from bit counts...
#define UMF_BIT_MASK(x) ((1 << x) - 1)
#define UMF_CHANNEL_ID_MASK    UMF_BIT_MASK(UMF_CHANNEL_ID_BITS)
#define UMF_SERVICE_ID_MASK    UMF_BIT_MASK(UMF_SERVICE_ID_BITS)
#define UMF_METHOD_ID_MASK     UMF_BIT_MASK(UMF_METHOD_ID_BITS)
#define UMF_MSG_LENGTH_MASK    UMF_BIT_MASK(UMF_MSG_LENGTH_BITS)


// ================ UMF Message ================

typedef class UMF_MESSAGE_CLASS* UMF_MESSAGE;
class UMF_MESSAGE_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:   
    // header info
    UINT32 channelID;
    UINT32 serviceID;
    UINT32 methodID;
    UINT32 length;
    
    // message
    unsigned char* message;
    int readIndex;
    int writeIndex;

    // links
    UMF_MESSAGE next;
    
  public:
    // constructors and destructor
    UMF_MESSAGE_CLASS();
    ~UMF_MESSAGE_CLASS();
    
    void Init(PLATFORMS_MODULE p);

    // clear
    void Clear();
    
    // allocation and de-allocation: these methods pipe
    // through to the allocator
    static UMF_MESSAGE New();
    void               Delete();

    // accessors
    int                GetChannelID()  { return channelID; }
    int                GetServiceID()  { return serviceID; }
    int                GetMethodID()   { return methodID;  }
    int                GetLength()     { return length;    }
    unsigned char*     GetMessage()    { return message;   }
    
    // header modifiers
    void               SetChannelID(int cid)   { channelID = cid; }
    void               SetServiceID(int sid)   { serviceID = sid; }
    void               SetMethodID(int mid)    { methodID  = mid; }
    void               SetLength(int len)      { length    = len; }
    
    // other header utilities
    inline void        DecodeHeader(unsigned char header[]);
    inline void        DecodeHeader(UMF_CHUNK chunk);
    inline void        EncodeHeader(unsigned char buf[]) const;
    inline UMF_CHUNK   EncodeHeader() const;
    
    // marshallers
    void               StartAppend();
    bool               CanAppend();
    
    void               AppendBytes(int nbytes, unsigned char data[]);
    void               AppendUINT8(UINT8 data);
    void               AppendUINT32(UINT32 data);
    void               AppendUINT64(UINT64 data);
    void               AppendUINT(UINT64 data, int nbytes);
    void               AppendChunk(UMF_CHUNK chunk);
    void               AppendChunks(int nchunks, UMF_CHUNK chunks[]);
    
    // demarshallers
    void               StartExtract();
    bool               CanExtract();
    void               CheckExtractSanity(int nbytes);
    
    void               ExtractBytes(int nbytes, unsigned char data[]);
    UINT8              ExtractUINT8();
    UINT32             ExtractUINT32();
    UINT64             ExtractUINT64();
    UINT64             ExtractUINT(int nbytes);
    UMF_CHUNK          ExtractChunk();
    
    void               StartReverseExtract();
    bool               CanReverseExtract();

    UMF_CHUNK          ReverseExtractChunk();
    
    // other
    void               Print(ostream &out);
    int                BytesUnwritten() { return length - writeIndex; }

    // links
    UMF_MESSAGE        GetNext()              { return next; }
    void               SetNext(UMF_MESSAGE m) { next = m; }

};


//
// Inline, performance critical routines...
//

// decode header from chunk
inline void
UMF_MESSAGE_CLASS::DecodeHeader(
    UMF_CHUNK chunk)
{
    // note: length in encoded header is in terms of number of chunks
    length = UMF_CHUNK_BYTES * (chunk & UMF_MSG_LENGTH_MASK);
    chunk >>= UMF_MSG_LENGTH_BITS;

    methodID  = chunk & UMF_METHOD_ID_MASK;
    chunk >>= UMF_METHOD_ID_BITS;

    serviceID = chunk & UMF_SERVICE_ID_MASK;
    chunk >>= UMF_SERVICE_ID_BITS;

    channelID = chunk & UMF_CHANNEL_ID_MASK;

    if (length > UMF_MAX_MSG_BYTES)
    {
        cerr << "umf: message size too long: " << length << endl;
        CallbackExit(1);
    }
}


// encode a header chunk from my internal info
inline UMF_CHUNK
UMF_MESSAGE_CLASS::EncodeHeader() const
{
    UMF_CHUNK chunk;

    // convert length to number of chunks
    unsigned int num_chunks = (length % UMF_CHUNK_BYTES) == 0 ?
                              (length / UMF_CHUNK_BYTES)      :
                              (length / UMF_CHUNK_BYTES) + 1;

    chunk = channelID;

    chunk <<= UMF_SERVICE_ID_BITS;
    chunk |= serviceID;

    chunk <<= UMF_METHOD_ID_BITS;
    chunk |= methodID;

    chunk <<= UMF_MSG_LENGTH_BITS;
    chunk |= num_chunks;

    return chunk;
}


//
// Char array based header encode/decode.  Both routines depend on the machine
// being little endian and headers being 32 bits.
//
inline void
UMF_MESSAGE_CLASS::DecodeHeader(
    unsigned char header[])
{
    UMF_CHUNK chunk = *(UINT32 *) header;
    DecodeHeader(chunk);
}


inline void
UMF_MESSAGE_CLASS::EncodeHeader(
    unsigned char buf[]) const
{
    UMF_CHUNK chunk = EncodeHeader();

    *(UINT32*) buf = chunk;
}


#endif
