//
// Copyright (C) 2010 Intel Corporation
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


//
// Brute force check of hash functions to confirm that each input hashes
// to a unique output and that the inverse functions are correct.
//
// Hash functions are used in hash-bits.bsv in the parent directory.
//

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

uint32_t bits[0x8000000];

uint8_t getBit(uint32_t b)
{
    uint32_t idx = b / 32;
    uint32_t mask = 1;

    if ((b & 31) != 0)
        mask <<= (b & 31);

    return (bits[idx] & mask) ? 1 : 0;
}


void setBit(uint32_t b)
{
    uint32_t idx = b / 32;
    uint32_t mask = 1;

    if ((b & 31) != 0)
        mask <<= (b & 31);

    bits[idx] |= mask;
}

uint32_t crc32(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 32; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^ 
              d[16] ^ d[12] ^ d[10] ^ d[9] ^ d[6] ^ d[0];
    hash[1] = d[28] ^ d[27] ^ d[24] ^ d[17] ^ d[16] ^ d[13] ^ d[12] ^ 
              d[11] ^ d[9] ^ d[7] ^ d[6] ^ d[1] ^ d[0];
    hash[2] = d[31] ^ d[30] ^ d[26] ^ d[24] ^ d[18] ^ d[17] ^ d[16] ^ 
              d[14] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[2] ^ 
              d[1] ^ d[0];
    hash[3] = d[31] ^ d[27] ^ d[25] ^ d[19] ^ d[18] ^ d[17] ^ d[15] ^ 
              d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[3] ^ d[2] ^ 
              d[1];
    hash[4] = d[31] ^ d[30] ^ d[29] ^ d[25] ^ d[24] ^ d[20] ^ d[19] ^ 
              d[18] ^ d[15] ^ d[12] ^ d[11] ^ d[8] ^ d[6] ^ d[4] ^ 
              d[3] ^ d[2] ^ d[0];
    hash[5] = d[29] ^ d[28] ^ d[24] ^ d[21] ^ d[20] ^ d[19] ^ d[13] ^ 
              d[10] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[1] ^ d[0];
    hash[6] = d[30] ^ d[29] ^ d[25] ^ d[22] ^ d[21] ^ d[20] ^ d[14] ^ 
              d[11] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1];
    hash[7] = d[29] ^ d[28] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ 
              d[16] ^ d[15] ^ d[10] ^ d[8] ^ d[7] ^ d[5] ^ d[3] ^ 
              d[2] ^ d[0];
    hash[8] = d[31] ^ d[28] ^ d[23] ^ d[22] ^ d[17] ^ d[12] ^ d[11] ^ 
              d[10] ^ d[8] ^ d[4] ^ d[3] ^ d[1] ^ d[0];
    hash[9] = d[29] ^ d[24] ^ d[23] ^ d[18] ^ d[13] ^ d[12] ^ d[11] ^ 
              d[9] ^ d[5] ^ d[4] ^ d[2] ^ d[1];
    hash[10] = d[31] ^ d[29] ^ d[28] ^ d[26] ^ d[19] ^ d[16] ^ d[14] ^ 
               d[13] ^ d[9] ^ d[5] ^ d[3] ^ d[2] ^ d[0];
    hash[11] = d[31] ^ d[28] ^ d[27] ^ d[26] ^ d[25] ^ d[24] ^ d[20] ^ 
               d[17] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[9] ^ d[4] ^ 
               d[3] ^ d[1] ^ d[0];
    hash[12] = d[31] ^ d[30] ^ d[27] ^ d[24] ^ d[21] ^ d[18] ^ d[17] ^ 
               d[15] ^ d[13] ^ d[12] ^ d[9] ^ d[6] ^ d[5] ^ d[4] ^ 
               d[2] ^ d[1] ^ d[0];
    hash[13] = d[31] ^ d[28] ^ d[25] ^ d[22] ^ d[19] ^ d[18] ^ d[16] ^ 
               d[14] ^ d[13] ^ d[10] ^ d[7] ^ d[6] ^ d[5] ^ d[3] ^ 
               d[2] ^ d[1];
    hash[14] = d[29] ^ d[26] ^ d[23] ^ d[20] ^ d[19] ^ d[17] ^ d[15] ^ 
               d[14] ^ d[11] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[3] ^ 
               d[2];
    hash[15] = d[30] ^ d[27] ^ d[24] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ 
               d[15] ^ d[12] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[4] ^ 
               d[3];
    hash[16] = d[30] ^ d[29] ^ d[26] ^ d[24] ^ d[22] ^ d[21] ^ d[19] ^ 
               d[17] ^ d[13] ^ d[12] ^ d[8] ^ d[5] ^ d[4] ^ d[0];
    hash[17] = d[31] ^ d[30] ^ d[27] ^ d[25] ^ d[23] ^ d[22] ^ d[20] ^ 
               d[18] ^ d[14] ^ d[13] ^ d[9] ^ d[6] ^ d[5] ^ d[1];
    hash[18] = d[31] ^ d[28] ^ d[26] ^ d[24] ^ d[23] ^ d[21] ^ d[19] ^ 
               d[15] ^ d[14] ^ d[10] ^ d[7] ^ d[6] ^ d[2];
    hash[19] = d[29] ^ d[27] ^ d[25] ^ d[24] ^ d[22] ^ d[20] ^ d[16] ^ 
               d[15] ^ d[11] ^ d[8] ^ d[7] ^ d[3];
    hash[20] = d[30] ^ d[28] ^ d[26] ^ d[25] ^ d[23] ^ d[21] ^ d[17] ^ 
               d[16] ^ d[12] ^ d[9] ^ d[8] ^ d[4];
    hash[21] = d[31] ^ d[29] ^ d[27] ^ d[26] ^ d[24] ^ d[22] ^ d[18] ^ 
               d[17] ^ d[13] ^ d[10] ^ d[9] ^ d[5];
    hash[22] = d[31] ^ d[29] ^ d[27] ^ d[26] ^ d[24] ^ d[23] ^ d[19] ^ 
               d[18] ^ d[16] ^ d[14] ^ d[12] ^ d[11] ^ d[9] ^ d[0];
    hash[23] = d[31] ^ d[29] ^ d[27] ^ d[26] ^ d[20] ^ d[19] ^ d[17] ^ 
               d[16] ^ d[15] ^ d[13] ^ d[9] ^ d[6] ^ d[1] ^ d[0];
    hash[24] = d[30] ^ d[28] ^ d[27] ^ d[21] ^ d[20] ^ d[18] ^ d[17] ^ 
               d[16] ^ d[14] ^ d[10] ^ d[7] ^ d[2] ^ d[1];
    hash[25] = d[31] ^ d[29] ^ d[28] ^ d[22] ^ d[21] ^ d[19] ^ d[18] ^ 
               d[17] ^ d[15] ^ d[11] ^ d[8] ^ d[3] ^ d[2];
    hash[26] = d[31] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ 
               d[20] ^ d[19] ^ d[18] ^ d[10] ^ d[6] ^ d[4] ^ d[3] ^ 
               d[0];
    hash[27] = d[29] ^ d[27] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ 
               d[20] ^ d[19] ^ d[11] ^ d[7] ^ d[5] ^ d[4] ^ d[1];
    hash[28] = d[30] ^ d[28] ^ d[27] ^ d[26] ^ d[25] ^ d[24] ^ d[22] ^ 
               d[21] ^ d[20] ^ d[12] ^ d[8] ^ d[6] ^ d[5] ^ d[2];
    hash[29] = d[31] ^ d[29] ^ d[28] ^ d[27] ^ d[26] ^ d[25] ^ d[23] ^ 
               d[22] ^ d[21] ^ d[13] ^ d[9] ^ d[7] ^ d[6] ^ d[3];
    hash[30] = d[30] ^ d[29] ^ d[28] ^ d[27] ^ d[26] ^ d[24] ^ d[23] ^ 
               d[22] ^ d[14] ^ d[10] ^ d[8] ^ d[7] ^ d[4];
    hash[31] = d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[27] ^ d[25] ^ d[24] ^ 
               d[23] ^ d[15] ^ d[11] ^ d[9] ^ d[8] ^ d[5];

    for (i = 31; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc32inv(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 32; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[31] ^ d[29] ^ d[27] ^ d[25] ^ d[23] ^ d[21] ^ d[20] ^
              d[16] ^ d[14] ^ d[9] ^ d[5] ^ d[2] ^ d[1];
    hash[1] = d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[27] ^ d[26] ^ d[25] ^
              d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[17] ^ d[16] ^ d[15] ^
              d[14] ^ d[10] ^ d[9] ^ d[6] ^ d[5] ^ d[3] ^ d[1] ^
              d[0];
    hash[2] = d[30] ^ d[28] ^ d[26] ^ d[24] ^ d[20] ^ d[18] ^ d[17] ^
              d[15] ^ d[14] ^ d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[6] ^
              d[5] ^ d[4];
    hash[3] = d[31] ^ d[29] ^ d[27] ^ d[25] ^ d[21] ^ d[19] ^ d[18] ^
              d[16] ^ d[15] ^ d[12] ^ d[11] ^ d[10] ^ d[8] ^ d[7] ^
              d[6] ^ d[5] ^ d[0];
    hash[4] = d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[27] ^ d[26] ^ d[25] ^
              d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[14] ^ d[13] ^
              d[12] ^ d[11] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[2] ^
              d[0];
    hash[5] = d[30] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^ d[22] ^ d[21] ^
              d[18] ^ d[16] ^ d[15] ^ d[13] ^ d[12] ^ d[8] ^ d[7] ^
              d[6] ^ d[5] ^ d[3] ^ d[2];
    hash[6] = d[31] ^ d[29] ^ d[27] ^ d[26] ^ d[25] ^ d[23] ^ d[22] ^
              d[19] ^ d[17] ^ d[16] ^ d[14] ^ d[13] ^ d[9] ^ d[8] ^
              d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[0];
    hash[7] = d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^
              d[21] ^ d[18] ^ d[17] ^ d[16] ^ d[15] ^ d[10] ^ d[8] ^
              d[7] ^ d[4] ^ d[2] ^ d[0];
    hash[8] = d[30] ^ d[26] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[19] ^
              d[18] ^ d[17] ^ d[14] ^ d[11] ^ d[8] ^ d[3] ^ d[2];
    hash[9] = d[31] ^ d[27] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^
              d[19] ^ d[18] ^ d[15] ^ d[12] ^ d[9] ^ d[4] ^ d[3];
    hash[10] = d[31] ^ d[29] ^ d[28] ^ d[27] ^ d[24] ^ d[22] ^ d[19] ^
               d[14] ^ d[13] ^ d[10] ^ d[9] ^ d[4] ^ d[2] ^ d[1] ^
               d[0];
    hash[11] = d[31] ^ d[30] ^ d[28] ^ d[27] ^ d[21] ^ d[16] ^ d[15] ^
               d[11] ^ d[10] ^ d[9] ^ d[3] ^ d[0];
    hash[12] = d[28] ^ d[27] ^ d[25] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^
               d[17] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[5] ^
               d[4] ^ d[2];
    hash[13] = d[29] ^ d[28] ^ d[26] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^
               d[18] ^ d[15] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[6] ^
               d[5] ^ d[3] ^ d[0];
    hash[14] = d[30] ^ d[29] ^ d[27] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^
               d[19] ^ d[16] ^ d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[7] ^
               d[6] ^ d[4] ^ d[1];
    hash[15] = d[31] ^ d[30] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^
               d[20] ^ d[17] ^ d[15] ^ d[14] ^ d[13] ^ d[12] ^ d[8] ^
               d[7] ^ d[5] ^ d[2] ^ d[0];
    hash[16] = d[26] ^ d[24] ^ d[23] ^ d[20] ^ d[18] ^ d[15] ^ d[13] ^
               d[8] ^ d[6] ^ d[5] ^ d[3] ^ d[2] ^ d[0];
    hash[17] = d[27] ^ d[25] ^ d[24] ^ d[21] ^ d[19] ^ d[16] ^ d[14] ^
               d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[1];
    hash[18] = d[28] ^ d[26] ^ d[25] ^ d[22] ^ d[20] ^ d[17] ^ d[15] ^
               d[10] ^ d[8] ^ d[7] ^ d[5] ^ d[4] ^ d[2];
    hash[19] = d[29] ^ d[27] ^ d[26] ^ d[23] ^ d[21] ^ d[18] ^ d[16] ^
               d[11] ^ d[9] ^ d[8] ^ d[6] ^ d[5] ^ d[3];
    hash[20] = d[30] ^ d[28] ^ d[27] ^ d[24] ^ d[22] ^ d[19] ^ d[17] ^
               d[12] ^ d[10] ^ d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[0];
    hash[21] = d[31] ^ d[29] ^ d[28] ^ d[25] ^ d[23] ^ d[20] ^ d[18] ^
               d[13] ^ d[11] ^ d[10] ^ d[8] ^ d[7] ^ d[5] ^ d[1] ^
               d[0];
    hash[22] = d[31] ^ d[30] ^ d[27] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^
               d[20] ^ d[19] ^ d[16] ^ d[12] ^ d[11] ^ d[8] ^ d[6] ^
               d[5] ^ d[0];
    hash[23] = d[29] ^ d[28] ^ d[26] ^ d[24] ^ d[23] ^ d[17] ^ d[16] ^
               d[14] ^ d[13] ^ d[12] ^ d[7] ^ d[6] ^ d[5] ^ d[2] ^
               d[0];
    hash[24] = d[30] ^ d[29] ^ d[27] ^ d[25] ^ d[24] ^ d[18] ^ d[17] ^
               d[15] ^ d[14] ^ d[13] ^ d[8] ^ d[7] ^ d[6] ^ d[3] ^
               d[1] ^ d[0];
    hash[25] = d[31] ^ d[30] ^ d[28] ^ d[26] ^ d[25] ^ d[19] ^ d[18] ^
               d[16] ^ d[15] ^ d[14] ^ d[9] ^ d[8] ^ d[7] ^ d[4] ^
               d[2] ^ d[1] ^ d[0];
    hash[26] = d[26] ^ d[25] ^ d[23] ^ d[21] ^ d[19] ^ d[17] ^ d[15] ^
               d[14] ^ d[10] ^ d[8] ^ d[3];
    hash[27] = d[27] ^ d[26] ^ d[24] ^ d[22] ^ d[20] ^ d[18] ^ d[16] ^
               d[15] ^ d[11] ^ d[9] ^ d[4] ^ d[0];
    hash[28] = d[28] ^ d[27] ^ d[25] ^ d[23] ^ d[21] ^ d[19] ^ d[17] ^
               d[16] ^ d[12] ^ d[10] ^ d[5] ^ d[1];
    hash[29] = d[29] ^ d[28] ^ d[26] ^ d[24] ^ d[22] ^ d[20] ^ d[18] ^
               d[17] ^ d[13] ^ d[11] ^ d[6] ^ d[2];
    hash[30] = d[30] ^ d[29] ^ d[27] ^ d[25] ^ d[23] ^ d[21] ^ d[19] ^
               d[18] ^ d[14] ^ d[12] ^ d[7] ^ d[3] ^ d[0];
    hash[31] = d[31] ^ d[30] ^ d[28] ^ d[26] ^ d[24] ^ d[22] ^ d[20] ^
               d[19] ^ d[15] ^ d[13] ^ d[8] ^ d[4] ^ d[1] ^ d[0];

    for (i = 31; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc24(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 24; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[17] ^ 
              d[16] ^ d[14] ^ d[10] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ 
              d[1] ^ d[0];
    hash[1] = d[16] ^ d[15] ^ d[14] ^ d[11] ^ d[10] ^ d[6] ^ d[0];
    hash[2] = d[17] ^ d[16] ^ d[15] ^ d[12] ^ d[11] ^ d[7] ^ d[1];
    hash[3] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[14] ^ d[13] ^ 
              d[12] ^ d[10] ^ d[8] ^ d[5] ^ d[4] ^ d[3] ^ d[1] ^ 
              d[0];
    hash[4] = d[19] ^ d[18] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^ d[11] ^ 
              d[10] ^ d[9] ^ d[6] ^ d[3] ^ d[0];
    hash[5] = d[23] ^ d[22] ^ d[21] ^ d[12] ^ d[11] ^ d[7] ^ d[5] ^ 
              d[3] ^ d[2] ^ d[0];
    hash[6] = d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[17] ^ d[16] ^ d[14] ^ 
              d[13] ^ d[12] ^ d[10] ^ d[8] ^ d[6] ^ d[5] ^ d[2] ^ 
              d[0];
    hash[7] = d[23] ^ d[16] ^ d[15] ^ d[13] ^ d[11] ^ d[10] ^ d[9] ^ 
              d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[0];
    hash[8] = d[17] ^ d[16] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ d[8] ^ 
              d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[1];
    hash[9] = d[18] ^ d[17] ^ d[15] ^ d[13] ^ d[12] ^ d[11] ^ d[9] ^ 
              d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[2];
    hash[10] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[17] ^ d[13] ^ d[12] ^ 
               d[9] ^ d[8] ^ d[7] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[11] = d[20] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ 
               d[4] ^ d[0];
    hash[12] = d[21] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ 
               d[5] ^ d[1];
    hash[13] = d[22] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ 
               d[6] ^ d[2];
    hash[14] = d[21] ^ d[18] ^ d[17] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ 
               d[7] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[15] = d[22] ^ d[19] ^ d[18] ^ d[15] ^ d[13] ^ d[12] ^ d[11] ^ 
               d[8] ^ d[6] ^ d[5] ^ d[3] ^ d[2] ^ d[1];
    hash[16] = d[23] ^ d[20] ^ d[19] ^ d[16] ^ d[14] ^ d[13] ^ d[12] ^ 
               d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[2];
    hash[17] = d[23] ^ d[22] ^ d[19] ^ d[18] ^ d[16] ^ d[15] ^ d[13] ^ 
               d[8] ^ d[7] ^ d[2] ^ d[1] ^ d[0];
    hash[18] = d[22] ^ d[21] ^ d[18] ^ d[10] ^ d[9] ^ d[8] ^ d[5] ^ 
               d[4] ^ d[0];
    hash[19] = d[23] ^ d[22] ^ d[19] ^ d[11] ^ d[10] ^ d[9] ^ d[6] ^ 
               d[5] ^ d[1];
    hash[20] = d[23] ^ d[20] ^ d[12] ^ d[11] ^ d[10] ^ d[7] ^ d[6] ^ 
               d[2];
    hash[21] = d[21] ^ d[13] ^ d[12] ^ d[11] ^ d[8] ^ d[7] ^ d[3];
    hash[22] = d[22] ^ d[14] ^ d[13] ^ d[12] ^ d[9] ^ d[8] ^ d[4];
    hash[23] = d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[17] ^ d[16] ^ 
               d[15] ^ d[13] ^ d[9] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ 
               d[0];

    for (i = 23; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc24inv(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 24; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[23] ^ d[22] ^ d[19] ^ d[17] ^ d[14] ^ d[13] ^ d[12] ^
              d[9] ^ d[7] ^ d[6] ^ d[1] ^ d[0];
    hash[1] = d[22] ^ d[20] ^ d[19] ^ d[18] ^ d[17] ^ d[15] ^ d[12] ^
              d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[2];
    hash[2] = d[23] ^ d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[16] ^ d[13] ^
              d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[3];
    hash[3] = d[23] ^ d[21] ^ d[20] ^ d[13] ^ d[11] ^ d[10] ^ d[9] ^
              d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[1] ^ d[0];
    hash[4] = d[23] ^ d[21] ^ d[19] ^ d[17] ^ d[13] ^ d[11] ^ d[10] ^
              d[8] ^ d[6] ^ d[5] ^ d[2];
    hash[5] = d[23] ^ d[20] ^ d[19] ^ d[18] ^ d[17] ^ d[13] ^ d[11] ^
              d[3] ^ d[1];
    hash[6] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[17] ^ d[13] ^
              d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[7] = d[21] ^ d[18] ^ d[17] ^ d[13] ^ d[12] ^ d[10] ^ d[9] ^
              d[8] ^ d[6] ^ d[5] ^ d[3] ^ d[2];
    hash[8] = d[22] ^ d[19] ^ d[18] ^ d[14] ^ d[13] ^ d[11] ^ d[10] ^
              d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[3];
    hash[9] = d[23] ^ d[20] ^ d[19] ^ d[15] ^ d[14] ^ d[12] ^ d[11] ^
              d[10] ^ d[8] ^ d[7] ^ d[5] ^ d[4] ^ d[0];
    hash[10] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[17] ^ d[16] ^
               d[15] ^ d[14] ^ d[11] ^ d[8] ^ d[7] ^ d[5];
    hash[11] = d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[16] ^ d[15] ^ d[14] ^
               d[13] ^ d[8] ^ d[7] ^ d[1];
    hash[12] = d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[17] ^ d[16] ^ d[15] ^
               d[14] ^ d[9] ^ d[8] ^ d[2];
    hash[13] = d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[17] ^ d[16] ^
               d[15] ^ d[10] ^ d[9] ^ d[3] ^ d[0];
    hash[14] = d[21] ^ d[18] ^ d[16] ^ d[14] ^ d[13] ^ d[12] ^ d[11] ^
               d[10] ^ d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[0];
    hash[15] = d[22] ^ d[19] ^ d[17] ^ d[15] ^ d[14] ^ d[13] ^ d[12] ^
               d[11] ^ d[10] ^ d[8] ^ d[7] ^ d[5] ^ d[1] ^ d[0];
    hash[16] = d[23] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[14] ^ d[13] ^
               d[12] ^ d[11] ^ d[9] ^ d[8] ^ d[6] ^ d[2] ^ d[1];
    hash[17] = d[23] ^ d[22] ^ d[21] ^ d[16] ^ d[15] ^ d[10] ^ d[6] ^
               d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[18] = d[19] ^ d[16] ^ d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[9] ^
               d[6] ^ d[4] ^ d[3] ^ d[2] ^ d[0];
    hash[19] = d[20] ^ d[17] ^ d[15] ^ d[14] ^ d[13] ^ d[12] ^ d[10] ^
               d[7] ^ d[5] ^ d[4] ^ d[3] ^ d[1];
    hash[20] = d[21] ^ d[18] ^ d[16] ^ d[15] ^ d[14] ^ d[13] ^ d[11] ^
               d[8] ^ d[6] ^ d[5] ^ d[4] ^ d[2];
    hash[21] = d[22] ^ d[19] ^ d[17] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^
               d[9] ^ d[7] ^ d[6] ^ d[5] ^ d[3];
    hash[22] = d[23] ^ d[20] ^ d[18] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^
               d[10] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[0];
    hash[23] = d[23] ^ d[22] ^ d[21] ^ d[18] ^ d[16] ^ d[13] ^ d[12] ^
               d[11] ^ d[8] ^ d[6] ^ d[5] ^ d[0];

    for (i = 23; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc16(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 16; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[15] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^
              d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[1] = d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^
              d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1];
    hash[2] = d[14] ^ d[1] ^ d[0];
    hash[3] = d[15] ^ d[2] ^ d[1];
    hash[4] = d[3] ^ d[2];
    hash[5] = d[4] ^ d[3];
    hash[6] = d[5] ^ d[4];
    hash[7] = d[6] ^ d[5];
    hash[8] = d[7] ^ d[6];
    hash[9] = d[8] ^ d[7];
    hash[10] = d[9] ^ d[8];
    hash[11] = d[10] ^ d[9];
    hash[12] = d[11] ^ d[10];
    hash[13] = d[12] ^ d[11];
    hash[14] = d[13] ^ d[12];
    hash[15] = d[15] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^
               d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];

    for (i = 15; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc16inv(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 16; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[14] ^ d[12] ^ d[10] ^ d[8] ^ d[6] ^ d[4] ^ d[2] ^
              d[1];
    hash[1] = d[15] ^ d[13] ^ d[11] ^ d[9] ^ d[7] ^ d[5] ^ d[3] ^
              d[2];
    hash[2] = d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[3] = d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[4] = d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[5] = d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[6] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^
              d[0];
    hash[7] = d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^
              d[1] ^ d[0];
    hash[8] = d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^
              d[2] ^ d[1] ^ d[0];
    hash[9] = d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^
              d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[10] = d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^
               d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[11] = d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^
               d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[12] = d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^
               d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[13] = d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^
               d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^
               d[0];
    hash[14] = d[15] ^ d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^
               d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^
               d[1];
    hash[15] = d[15] ^ d[13] ^ d[11] ^ d[9] ^ d[7] ^ d[5] ^ d[3] ^
               d[1] ^ d[0];

    for (i = 15; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc8(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 8; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[7] ^ d[6] ^ d[3] ^ d[1] ^ d[0];
    hash[1] = d[7] ^ d[4] ^ d[2] ^ d[1];
    hash[2] = d[7] ^ d[6] ^ d[5] ^ d[2] ^ d[1] ^ d[0];
    hash[3] = d[7] ^ d[6] ^ d[3] ^ d[2] ^ d[1];
    hash[4] = d[6] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[5] = d[7] ^ d[5] ^ d[3] ^ d[2] ^ d[1];
    hash[6] = d[7] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[7] = d[7] ^ d[6] ^ d[5] ^ d[2] ^ d[0];

    for (i = 7; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc8inv(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 8; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[6] ^ d[1];
    hash[1] = d[7] ^ d[2];
    hash[2] = d[6] ^ d[3] ^ d[1] ^ d[0];
    hash[3] = d[7] ^ d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[4] = d[6] ^ d[5] ^ d[3] ^ d[2];
    hash[5] = d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[0];
    hash[6] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[0];
    hash[7] = d[7] ^ d[5] ^ d[0];

    for (i = 7; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc7(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 7; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[4] ^ d[0];
    hash[1] = d[5] ^ d[1];
    hash[2] = d[6] ^ d[2];
    hash[3] = d[4] ^ d[3] ^ d[0];
    hash[4] = d[5] ^ d[4] ^ d[1];
    hash[5] = d[6] ^ d[5] ^ d[2];
    hash[6] = d[6] ^ d[3];

    for (i = 6; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc7inv(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 7; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[4] ^ d[1] ^ d[0];
    hash[1] = d[5] ^ d[2] ^ d[1];
    hash[2] = d[6] ^ d[3] ^ d[2] ^ d[0];
    hash[3] = d[3] ^ d[0];
    hash[4] = d[4] ^ d[1];
    hash[5] = d[5] ^ d[2];
    hash[6] = d[6] ^ d[3] ^ d[0];

    for (i = 6; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc6(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 6; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[5] ^ d[0];
    hash[1] = d[5] ^ d[1] ^ d[0];
    hash[2] = d[2] ^ d[1];
    hash[3] = d[3] ^ d[2];
    hash[4] = d[4] ^ d[3];
    hash[5] = d[5] ^ d[4];

    for (i = 5; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc6inv(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 6; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1];
    hash[1] = d[1] ^ d[0];
    hash[2] = d[2] ^ d[1] ^ d[0];
    hash[3] = d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[4] = d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];
    hash[5] = d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0];

    for (i = 5; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc5(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 5; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[3] ^ d[0];
    hash[1] = d[4] ^ d[1];
    hash[2] = d[3] ^ d[2] ^ d[0];
    hash[3] = d[4] ^ d[3] ^ d[1];
    hash[4] = d[4] ^ d[2];

    for (i = 4; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc5inv(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 5; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[3] ^ d[1] ^ d[0];
    hash[1] = d[4] ^ d[2] ^ d[1] ^ d[0];
    hash[2] = d[2] ^ d[0];
    hash[3] = d[3] ^ d[1];
    hash[4] = d[4] ^ d[2] ^ d[0];

    for (i = 4; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc4(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 4; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[3] ^ d[0];
    hash[1] = d[3] ^ d[1] ^ d[0];
    hash[2] = d[2] ^ d[1];
    hash[3] = d[3] ^ d[2];

    for (i = 3; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


uint32_t crc4inv(uint32_t in)
{
    uint8_t d[32], hash[32];
    uint32_t in_r = in;
    uint32_t out = 0;
    int i;

    for (i = 0; i < 4; i++)
    {
        d[i] = in_r & 1;
        in_r >>= 1;
    }

    hash[0] = d[3] ^ d[2] ^ d[1];
    hash[1] = d[1] ^ d[0];
    hash[2] = d[2] ^ d[1] ^ d[0];
    hash[3] = d[3] ^ d[2] ^ d[1] ^ d[0];

    for (i = 3; i >= 0; i--)
    {
        out <<= 1;
        out |= hash[i];
    }

    return out;
}


main()
{
    uint64_t i;
    uint64_t c, c_inv;

    uint64_t max = 0x100 >> 1;

    for (i = 0; i < max; i++)
    {
        if ((i & 0xffffff) == 0)
        {
            fprintf(stderr, "0x%08x\n", (uint32_t)i);
        }

        c = crc7((uint32_t)i);
        c_inv = crc7inv(c);

        if (i != c_inv)
        {
            fprintf(stderr, "0x%08x => 0x%08x => 0x%08x inverse failed\n", (uint32_t)i, c, c_inv);
            exit(1);
        }

        if (getBit(c))
        {
            fprintf(stderr, "0x%08x => 0x%08x already set\n", (uint32_t)i, c);
            exit(1);
        }

        setBit(c);
    }

    for (i = 0; i < max / 32; i++)
    {
        if (bits[i] != 0xffffffff)
        {
            fprintf(stderr, "Unexpected (%d):  0x%08x\n", i, bits[i]);
            exit(1);
        }
    }
}
