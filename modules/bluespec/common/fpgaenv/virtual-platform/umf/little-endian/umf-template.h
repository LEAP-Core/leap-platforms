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
 * @file umf-template.h
 * @author Kermin Fleming
 * @brief A factory for creating umf messages.  Abstracts the message types carried by the underlying physical devices. 
 */


#ifndef __UMF_TEMPLATE__
#define __UMF_TEMPLATE__

#include <iostream>

#include <string.h>

#include "asim/syntax.h"
#include "asim/freelist.h"

#include "awb/provides/umf.h"

//using namespace std;

template <int channelIDBits, int serviceIDBits, int methodIDBits, int msgLengthBits> class UMF_MESSAGE_TEMPLATE_CLASS: public UMF_MESSAGE_CLASS
{
    private:

        // these should really not be static I think

        static const UMF_CHUNK channelIDMask = UMF_BIT_MASK(channelIDBits);
        static const UMF_CHUNK serviceIDMask = UMF_BIT_MASK(serviceIDBits);
        static const UMF_CHUNK methodIDMask  = UMF_BIT_MASK(methodIDBits);
        static const UMF_CHUNK msgLengthMask  = UMF_BIT_MASK(msgLengthBits);

        

    public:

    UMF_MESSAGE_TEMPLATE_CLASS(): UMF_MESSAGE_CLASS() 
    { 
      //        channelID = 0;
      //  methodID = 0;
      //  phyPvt = 0;
    };
 
    // decode header from chunk
    void DecodeHeader(UMF_CHUNK chunk)
    {

        header = chunk;

        // note: length in encoded header is in terms of number of chunks
        length = UMF_CHUNK_BYTES * (chunk & msgLengthMask);
        chunk >>= msgLengthBits;

        
        chunk >>= methodIDBits;

	serviceID = chunk & serviceIDMask;
        chunk >>= serviceIDBits;

        chunk >>= channelIDBits;
        phyPvt = chunk;

    }

    // encode a header chunk from my internal info                                                                                        
    UMF_CHUNK EncodeHeaderWithPhyChannelPvt(unsigned int pvt)
    {
        UMF_CHUNK chunk = 0;//phyPvt;
	
        unsigned int num_chunks = (length % UMF_CHUNK_BYTES) == 0 ?
                                      (length / UMF_CHUNK_BYTES):
                                      (length / UMF_CHUNK_BYTES) + 1;

        chunk <<= channelIDBits;

        chunk <<= serviceIDBits;
        chunk |= serviceID;
	
        chunk <<= methodIDBits;
        
        chunk <<= msgLengthBits;
        chunk |= num_chunks;

        return chunk;
    }



};

#endif
