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
#include "asim/provides/umf.h"
#include "platforms-module.h"

using namespace std;

// specific types for this UMF implementation
#if (UMF_CHUNK_BYTES == 4)
typedef UINT32 UMF_CHUNK;
#elif (UMF_CHUNK_BYTES == 8)
typedef UINT64 UMF_CHUNK;
#elif (UMF_CHUNK_BYTES == 16)
typedef UINT128 UMF_CHUNK;
#else
#error Unsupported UMF_CHUNK_BYTES
#endif

// Bit masks from bit counts...
#define UMF_BIT_MASK(x) ((1 << x) - 1)
#define UMF_CHANNEL_ID_MASK    UMF_BIT_MASK(UMF_CHANNEL_ID_BITS)
#define UMF_SERVICE_ID_MASK    UMF_BIT_MASK(UMF_SERVICE_ID_BITS)
#define UMF_METHOD_ID_MASK     UMF_BIT_MASK(UMF_METHOD_ID_BITS)
#define UMF_MSG_LENGTH_MASK    UMF_BIT_MASK(UMF_MSG_LENGTH_BITS)

// Forward declare allocator
class UMF_ALLOCATOR_CLASS;

// ================ UMF Message ================

typedef class UMF_MESSAGE_CLASS* UMF_MESSAGE;
class UMF_MESSAGE_CLASS: public ASIM_FREE_LIST_ELEMENT_CLASS<UMF_MESSAGE_CLASS>
{
  private:   
    // For now we use fixed sized message buffers to simplify allocation.
    unsigned char message[UMF_MAX_MSG_BYTES];
    int readIndex;
    int writeIndex;

    // links
    UMF_MESSAGE next;
    UMF_ALLOCATOR_CLASS *allocator;
    
  // Allows us to overload decoding of headers
  protected:

    // header info
    UINT32 channelID;
    UINT32 serviceID;
    UINT32 methodID;
    UINT32 length;
    UMF_CHUNK phyPvt;
    UMF_CHUNK header;
    

    // Make friends with the allocator 
    friend class UMF_ALLOCATOR_CLASS;

    void setAllocator(UMF_ALLOCATOR_CLASS *allocatorNew) { allocator = allocatorNew; }

  public:
    // constructor and destructor
    UMF_MESSAGE_CLASS();
    ~UMF_MESSAGE_CLASS();
    
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
    UMF_CHUNK          GetPhyPvt()     { return phyPvt;    }
    unsigned char*     GetMessage()    { return message;   }
    
    // header modifiers
    void               SetChannelID(int cid)          { channelID = cid; }
    void               SetServiceID(int sid)          { serviceID = sid; }
    void               SetMethodID(int mid)           { methodID  = mid; }
    void               SetLength(int len)             { length    = len; }
    void               SetPhyPvt(UMF_CHUNK phyPvtNew) { phyPvt    = phyPvtNew; }    


    // other header utilities
    virtual void        DecodeHeader(unsigned char header[]);
    virtual void       DecodeHeader(UMF_CHUNK chunk);
    virtual UMF_CHUNK   GetHeader();
    virtual void        EncodeHeader(unsigned char buf[]);
    virtual UMF_CHUNK   EncodeHeader();
    virtual UMF_CHUNK  EncodeHeaderWithPhyChannelPvt(unsigned int pvt); // We may want to make this pure virtual

    // marshallers
    void               StartAppend();
    bool               CanAppend();
    
    void               AppendBytes(int nbytes, unsigned char data[]);
    void               AppendUINT8(UINT8 data);
    void               AppendUINT16(UINT16 data);
    void               AppendUINT32(UINT32 data);
    void               AppendUINT64(UINT64 data);
    void               AppendUINT(UINT64 data, int nbytes);
    void               AppendChunk(UMF_CHUNK chunk);
    void               AppendChunks(int nchunks, UMF_CHUNK chunks[]);
    
    // Expose the append point as a raw pointer.  This breaks the layer
    // between a client or channel implementation and the marshalling
    // layer but can be much more efficient when a channel implemenation
    // understands the UMF layout since an entire buffer can be copied
    // at once.
    //
    // AppendRawPtr returns a pointer to the location where data should
    // be written.
    void*              AppendGetRawPtr();
    // Move the write index following completion of a raw append.
    void               AppendUpdateRawPtr(int nbytes);

    // demarshallers
    void               StartExtract();
    bool               CanExtract(int nbytes = 1) const;
    void               CheckExtractSanity(int nbytes);
    
    void               ExtractBytes(int nbytes, unsigned char data[]);
    UINT8              ExtractUINT8();
    UINT16             ExtractUINT16();
    UINT32             ExtractUINT32();
    UINT64             ExtractUINT64();
    UINT64             ExtractUINT(int nbytes);
    UMF_CHUNK          ExtractChunk();
    void               ExtractChunks(int nchunks, UMF_CHUNK dst[]);
    int                ExtractAllChunks(UMF_CHUNK dst[]);    

    // Analog of the raw append interface above.
    void*              ExtractGetRawPtr();
    void               ExtractUpdateRawPtr(int nbytes);

    // other
    void               Print(ostream &out);
    int                BytesUnwritten() const { return length - writeIndex; }
    int                ExtractBytesLeft() const { return writeIndex - readIndex; }
    int                GetReadIndex() const { return readIndex; };
    int                GetWriteIndex() const { return writeIndex; };

    // links
    UMF_MESSAGE        GetNext()              { return next; }
    void               SetNext(UMF_MESSAGE m) { next = m; }

};


//
// Inline, performance critical routines...
//

// constructor
inline
UMF_MESSAGE_CLASS::UMF_MESSAGE_CLASS()
{
    Clear();
}

// destructor
inline
UMF_MESSAGE_CLASS::~UMF_MESSAGE_CLASS()
{
}

// clear all message data
inline void
UMF_MESSAGE_CLASS::Clear()
{
    length     = 0;
    readIndex  = 0;
    writeIndex = 0;
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
UMF_MESSAGE_CLASS::CanExtract(int nbytes) const
{
    return (ExtractBytesLeft() >= nbytes);
}

inline void
UMF_MESSAGE_CLASS::CheckExtractSanity(
    int nbytes)
{
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

inline UINT16
UMF_MESSAGE_CLASS::ExtractUINT16()
{
    CheckExtractSanity(sizeof(UINT16));
    UINT16 retval = *(UINT16 *)(&message[readIndex]);
    readIndex += sizeof(UINT16);
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

inline UMF_CHUNK
UMF_MESSAGE_CLASS::ExtractChunk()
{
    CheckExtractSanity(sizeof(UMF_CHUNK));
    UMF_CHUNK retval = *(UMF_CHUNK *)(&message[readIndex]);
    readIndex += sizeof(UMF_CHUNK);
    return retval;
}


//
// ExtractChunks --
//     Copy multiple chunks.
//
inline void
UMF_MESSAGE_CLASS::ExtractChunks(int nchunks, UMF_CHUNK dst[])
{
    // Round length up to a multiple of chunks
    UINT32 len = (length + sizeof(UMF_CHUNK) - 1) & ~(sizeof(UMF_CHUNK) - 1);
    VERIFYX(nchunks * sizeof(UMF_CHUNK) + readIndex == len);

    const UMF_CHUNK* src = (UMF_CHUNK *)(&message[readIndex]);

    readIndex += nchunks * sizeof(UMF_CHUNK);

    while (nchunks--)
    {
        *dst++ = *src++;
    }
}


//
// ExtractAllChunks --
//     Manage a full extraction, returning the number of chunks
//     extracted.
//
inline int
UMF_MESSAGE_CLASS::ExtractAllChunks(UMF_CHUNK dst[])
{
    StartExtract();

    int n_chunks = 0;
    while (CanExtract())
    {
      *dst++ = ExtractChunk();
      n_chunks += 1;
    }

    return n_chunks;
}

inline void*
UMF_MESSAGE_CLASS::ExtractGetRawPtr()
{
    return &message[readIndex];
}

inline void
UMF_MESSAGE_CLASS::ExtractUpdateRawPtr(
    int nbytes)
{
    CheckExtractSanity(nbytes);
    readIndex += nbytes;
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
UMF_MESSAGE_CLASS::AppendUINT16(
    UINT16 data)
{
    ASSERT((writeIndex + sizeof(data)) <= length, "umf: message write overflow");

    *(UINT16*)&message[writeIndex] = data;
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

inline void*
UMF_MESSAGE_CLASS::AppendGetRawPtr()
{
    return &message[writeIndex];
}

inline void
UMF_MESSAGE_CLASS::AppendUpdateRawPtr(
    int nbytes)
{
    ASSERT((writeIndex + nbytes) <= length, "umf: message write overflow");

    writeIndex += nbytes;
}

#endif
