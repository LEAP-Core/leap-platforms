/*****************************************************************************
 * umf-template.h
 *
 * Copyright (C) 2013 Intel Corporation 
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
