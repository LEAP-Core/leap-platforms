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
