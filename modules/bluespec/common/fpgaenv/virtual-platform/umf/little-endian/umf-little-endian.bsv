//
// Copyright (C) 2009 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

`ifndef _UMF_
`define _UMF_

typedef TMul#(`UMF_CHUNK_BYTES, 8)  UMF_CHUNK_BITS;
typedef Bit#(UMF_CHUNK_BITS)        UMF_CHUNK;

typedef Bit#(`UMF_PHY_CHANNEL_RESERVED_BITS) UMF_PHY_CHANNEL_PVT;
typedef Bit#(`UMF_CHANNEL_ID_BITS)  UMF_CHANNEL_ID;
typedef Bit#(`UMF_SERVICE_ID_BITS)  UMF_SERVICE_ID;
typedef Bit#(`UMF_METHOD_ID_BITS)   UMF_METHOD_ID;
typedef Bit#(`UMF_MSG_LENGTH_BITS)  UMF_MSG_LENGTH;

//
// Packet header filler bits to make UMF_CHUNK and UMF_PACKET_header the same
// size.
//
typedef TSub#(UMF_CHUNK_BITS,
              TAdd#(`UMF_PHY_CHANNEL_RESERVED_BITS,
                    TAdd#(`UMF_CHANNEL_ID_BITS,
                          TAdd#(`UMF_SERVICE_ID_BITS,
                                TAdd#(`UMF_METHOD_ID_BITS,
                                      `UMF_MSG_LENGTH_BITS)))))
    UMF_PACKET_HEADER_FILLER_BITS;


typedef struct
{
    // Filler so packet header is the same size as a chunk.
    Bit#(UMF_PACKET_HEADER_FILLER_BITS) filler;

    // Reserved for use by the physical channel
    UMF_PHY_CHANNEL_PVT phyChannelPvt;

    UMF_CHANNEL_ID  channelID;
    UMF_SERVICE_ID  serviceID;
    UMF_METHOD_ID   methodID;
    UMF_MSG_LENGTH  numChunks;
}
UMF_PACKET_HEADER
    deriving (Eq, Bits);


typedef union tagged
{
    UMF_PACKET_HEADER UMF_PACKET_header;
    UMF_CHUNK         UMF_PACKET_dataChunk;
} UMF_PACKET
    deriving (Eq, Bits);

`endif
