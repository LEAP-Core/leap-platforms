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
// Discover the inverse of a CRC-based hashing function using matrix
// operations.
//

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>



//
// Define the base hash function here.
//

#define nBits 7

void init(uint64_t *vec)
{
    uint64_t mask;
    uint64_t d[nBits], hash[nBits];
    int i;

    mask = 1;
    for (i = 0; i < nBits; i++)
    {
        d[i] = mask;
        mask <<= 1;
    }
    
    hash[0] = d[4] ^ d[0];
    hash[1] = d[5] ^ d[1];
    hash[2] = d[6] ^ d[2];
    hash[3] = d[4] ^ d[3] ^ d[0];
    hash[4] = d[5] ^ d[4] ^ d[1];
    hash[5] = d[6] ^ d[5] ^ d[2];
    hash[6] = d[6] ^ d[3];

    for (i = 0; i < nBits; i++)
    {
        vec[i] = hash[i];
    }
}



void convertToIdentity(uint64_t *vec)
{
    int i, j;
    uint64_t mask_i = 1;
    for (i = 0; i < nBits; i++)
    {
        if ((vec[i] & mask_i) == 0)
        {
            // Must find a 1 later in the matrix and swap
            for (j = i + 1; j < nBits; j++)
            {
                if (vec[j] & mask_i)
                {
                    uint64_t swap;
                    swap = vec[i];
                    vec[i] = vec[j];
                    vec[j] = swap;
                    break;
                }
            }
            if ((vec[i] & mask_i) == 0)
            {
                fprintf(stderr, "Failed to find row to swap, i=%d\n", i);
                exit(1);
            }
        }

        for (j = 0; j < nBits; j++)
        {
            if ((i != j) && (vec[j] & mask_i))
            {
                vec[j] ^= vec[i];
            }
        }

        mask_i <<= 1;
    }
}



//
// Append the identity matrix to the existing one.  The identity matrix will
// be transformed to the inverse hashing matrix.
//
// This code only works for hash sizes up to 32 bits.  The identity matrix
// is stored in the upper 32 bits of 64 bit words.
//
void appendIdentity(uint64_t *vec)
{
    int i;
    uint64_t bit = 1L << 32;
    for (i = 0; i < nBits; i++)
    {
        vec[i] |= bit;
        bit <<= 1;
    }
}


void dumpVec(uint64_t *vec)
{
    printf("Inverse hash (%d):\n", nBits);

    int i, j, n;
    for (i = 0; i < nBits; i++)
    {
        uint64_t mask = (1L << 31);
        n = 0;
        printf("    hash[%d] =", i);
        for (j = 31; j >= 0; j--)
        {
            if ((vec[i] >> 32) & mask)
            {
                if (n != 0)
                {
                    printf(" ^");
                    if ((n % 7) == 0)
                    {
                        printf("\n             ");
                        if (i > 9) printf(" ");
                    }
                }
                printf(" d[%d]", j);
                n += 1;
            }
            mask >>= 1;
        }
        printf(";\n");
    }
}


main()
{
    static uint64_t gVec[nBits];

    init(gVec);
    appendIdentity(gVec);
    convertToIdentity(gVec);

    dumpVec(gVec);
}
