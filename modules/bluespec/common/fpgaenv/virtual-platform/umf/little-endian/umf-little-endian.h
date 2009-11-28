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

#include <string.h>

#include "asim/syntax.h"
#include "asim/freelist.h"

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
class UMF_MESSAGE_CLASS: public PLATFORMS_MODULE_CLASS,
                         public ASIM_FREE_LIST_ELEMENT_CLASS<UMF_MESSAGE_CLASS>
{
  private:   
    // header info
    UINT32 channelID;
    UINT32 serviceID;
    UINT32 methodID;
    UINT32 length;
    
    // For now we use fixed sized message buffers to simplify allocation.
    unsigned char message[UMF_MAX_MSG_BYTES];
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
    static void* operator new(size_t size);
    static void operator delete(void *obj);

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
    inline UMF_CHUNK   EncodeHeaderWithPhyChannelPvt(unsigned int pvt) const;

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
UMF_MESSAGE_CLASS::EncodeHeaderWithPhyChannelPvt(unsigned int pvt) const
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


inline UMF_CHUNK
UMF_MESSAGE_CLASS::EncodeHeader() const
{
    return EncodeHeaderWithPhyChannelPvt(0);
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


//
// demarshallers
//

inline void
UMF_MESSAGE_CLASS::StartExtract()
{
    readIndex = 0;
}

inline bool
UMF_MESSAGE_CLASS::CanExtract()
{
    return(readIndex < writeIndex);
}

inline void
UMF_MESSAGE_CLASS::CheckExtractSanity(
    int nbytes)
{
    ASSERT((readIndex + nbytes) <= writeIndex,
           "umf: message read underflow: readIndex = "
           << readIndex << " writeIndex = " << writeIndex
           << " nbytes = " << nbytes );

    WARN(writeIndex == length,
         "umf: [WARNING] attempt to read from incomplete message, are you sure you want to do this?");
}

inline void
UMF_MESSAGE_CLASS::ExtractBytes(
    int nbytes,
    unsigned char data[])
{
    CheckExtractSanity(nbytes);
    memcpy(data, &message[readIndex], nbytes);
    readIndex += nbytes;
}

inline UINT8
UMF_MESSAGE_CLASS::ExtractUINT8()
{
    CheckExtractSanity(sizeof(UINT8));
    UINT8 retval = *(UINT8 *)(&message[readIndex]);
    readIndex += sizeof(UINT8);
    return retval;
}

inline UINT32
UMF_MESSAGE_CLASS::ExtractUINT32()
{
    CheckExtractSanity(sizeof(UINT32));
    UINT32 retval = *(UINT32 *)(&message[readIndex]);
    readIndex += sizeof(UINT32);
    return retval;
}

inline UINT64
UMF_MESSAGE_CLASS::ExtractUINT64()
{
    CheckExtractSanity(sizeof(UINT64));
    UINT64 retval = *(UINT64 *)(&message[readIndex]);
    readIndex += sizeof(UINT64);
    return retval;
}

inline UINT64
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

inline UMF_CHUNK
UMF_MESSAGE_CLASS::ExtractChunk()
{
    CheckExtractSanity(sizeof(UMF_CHUNK));
    UMF_CHUNK retval = *(UMF_CHUNK *)(&message[readIndex]);
    readIndex += sizeof(UMF_CHUNK);
    return retval;
}


//
// marshallers: most of these are trivial for little-endian machines
//

inline void
UMF_MESSAGE_CLASS::StartAppend()
{
    writeIndex = 0;
}

inline bool
UMF_MESSAGE_CLASS::CanAppend()
{
    return(writeIndex < length);
}

inline void
UMF_MESSAGE_CLASS::AppendBytes(
    int nbytes,
    unsigned char data[])
{
    ASSERT((writeIndex + nbytes) <= length, "umf: message write overflow");

    memcpy(&message[writeIndex], data, nbytes);
    writeIndex += nbytes;
}

inline void
UMF_MESSAGE_CLASS::AppendUINT8(
    UINT8 data)
{
    ASSERT((writeIndex + sizeof(data)) <= length, "umf: message write overflow");

    *(UINT8*)&message[writeIndex] = data;
    writeIndex += sizeof(data);
}

inline void
UMF_MESSAGE_CLASS::AppendUINT32(
    UINT32 data)
{
    ASSERT((writeIndex + sizeof(data)) <= length, "umf: message write overflow");

    *(UINT32*)&message[writeIndex] = data;
    writeIndex += sizeof(data);
}

inline void
UMF_MESSAGE_CLASS::AppendUINT64(
    UINT64 data)
{
    ASSERT((writeIndex + sizeof(data)) <= length, "umf: message write overflow");

    *(UINT64*)&message[writeIndex] = data;
    writeIndex += sizeof(data);
}

inline void
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

inline void
UMF_MESSAGE_CLASS::AppendChunk(
    UMF_CHUNK chunk)
{
    ASSERT((writeIndex + sizeof(chunk)) <= length, "umf: message write overflow");

    *(UMF_CHUNK*)&message[writeIndex] = chunk;
    writeIndex += sizeof(chunk);
}

inline void
UMF_MESSAGE_CLASS::AppendChunks(
    int nchunks,
    UMF_CHUNK chunks[])
{
    AppendBytes(nchunks * sizeof(UMF_CHUNK), (unsigned char*) chunks);
}


//
// reverse (MSByte -> LSByte) read methods
//

inline void
UMF_MESSAGE_CLASS::StartReverseExtract()
{
    readIndex = length;
}

inline bool
UMF_MESSAGE_CLASS::CanReverseExtract()
{
    return(readIndex > 0);
}

inline UMF_CHUNK
UMF_MESSAGE_CLASS::ReverseExtractChunk()
{
    // if readIndex = i, we want to read bytes (i - CHUNK_SIZE) .. (i - 1)

    WARN(writeIndex == length,
         "umf: [WARNING] attempt to reverse-read from incomplete message, are you sure you want to do this?");

    // SPECIAL CASE: if this is the first reverse-read in a sequence, and
    //               the message length is not a multiple of UMF_CHUNK size,
    //               then pad this chunk
    UINT32 residue = readIndex % sizeof(UMF_CHUNK);
    if (residue != 0)
    {
        // sanity: this MUST be the first read
        ASSERTX(readIndex == length);

        // pad and read out the data
        UMF_CHUNK retval = 0;
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

#endif
