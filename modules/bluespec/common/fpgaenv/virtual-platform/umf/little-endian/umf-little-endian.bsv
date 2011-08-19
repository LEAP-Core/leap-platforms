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
    Bit#(filler_bits) filler;

    // Reserved for use by the physical channel
    Bit#(umf_phy_pvt)      phyChannelPvt;

    Bit#(umf_channel_id)   channelID;
    Bit#(umf_service_id)   serviceID;
    Bit#(umf_method_id)    methodID;
    Bit#(umf_message_len)  numChunks;
}
GENERIC_UMF_PACKET_HEADER#(numeric type umf_channel_id, numeric type umf_service_id,
                           numeric type umf_method_id,  numeric type umf_message_len,
                           numeric type umf_phy_pvt,    numeric type filler_bits)
                   
    deriving (Eq, Bits);

typedef GENERIC_UMF_PACKET_HEADER#(`UMF_CHANNEL_ID_BITS,`UMF_SERVICE_ID_BITS,`UMF_METHOD_ID_BITS,`UMF_MSG_LENGTH_BITS,`UMF_PHY_CHANNEL_RESERVED_BITS,UMF_PACKET_HEADER_FILLER_BITS) UMF_PACKET_HEADER;

typedef union tagged
{
    umf_packet_header UMF_PACKET_header;
    umf_chunk         UMF_PACKET_dataChunk;
} GENERIC_UMF_PACKET#(type umf_packet_header, type umf_chunk) 
  deriving (Eq, Bits);

typedef GENERIC_UMF_PACKET#(UMF_PACKET_HEADER,UMF_CHUNK) UMF_PACKET;

`endif
