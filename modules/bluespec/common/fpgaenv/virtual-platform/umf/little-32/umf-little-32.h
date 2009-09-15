/*****************************************************************************
 * umf-little-32.h
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
 * @file umf-little-32.h
 * @author Angshuman Parashar
 * @brief UMF interface
 */

//
// Little-endian UMF with 32-bit chunks
//

#ifndef __UMF__
#define __UMF__

#include <iostream>

#include "asim/syntax.h"
#include "platforms-module.h"

using namespace std;

#define UMF_MAX_LENGTH      1024
#define UMF_CHUNK_BITS      32
#define UMF_CHUNK_BYTES     4
#define UMF_CHUNK_LOG_BYTES 2

// specific types for this UMF implementation
typedef UINT32 UMF_CHUNK;

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
    void               DecodeHeader(unsigned char header[]);
    void               DecodeHeader(UMF_CHUNK chunk);
    void               EncodeHeader(unsigned char buf[]);
    UMF_CHUNK          EncodeHeader();
    
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

#endif
