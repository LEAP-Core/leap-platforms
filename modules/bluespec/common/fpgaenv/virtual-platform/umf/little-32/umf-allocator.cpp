/*****************************************************************************
 * umf-allocator.cpp
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
 * @file umf-allocator.cpp
 * @author Angshuman Parashar
 * @brief UMF Allocator implementation
 */

#include "asim/provides/umf.h"

using namespace std;

// self-instantiate
UMF_ALLOCATOR_CLASS UMF_ALLOCATOR_CLASS::instance;

// constructor
UMF_ALLOCATOR_CLASS::UMF_ALLOCATOR_CLASS()
{
    SetTraceableName("umf_allocator");

    // allocate pool
    pool = new UMF_MESSAGE_CLASS[UMF_POOL_SIZE];

    // setup free list
    freeList = pool;
    for (int i = 0; i < UMF_POOL_SIZE-1; i++)
    {
        pool[i].SetNext(&pool[i+1]);
    }
    pool[UMF_POOL_SIZE-1].SetNext(NULL);

    numFree = UMF_POOL_SIZE;
}

// destructor
UMF_ALLOCATOR_CLASS::~UMF_ALLOCATOR_CLASS()
{
    if (pool)
    {
        delete [] pool;
    }
    pool = NULL;
    freeList = NULL;
}

// allocate a new message
UMF_MESSAGE
UMF_ALLOCATOR_CLASS::New()
{
    // check if we have anything available
    if (freeList == NULL)
    {
        cerr << "UMF Allocator: ran out of resources, please increase pool size\n";
        exit(1);
    }

    // get one and update free list
    UMF_MESSAGE retval = freeList;
    freeList = freeList->GetNext();
    retval->SetNext(NULL);

    // track and log
    numFree--;
    T2("\t\tumf_allocator: New(): free list size = " << numFree);

    return retval;
}

// de-allocate a message
void
UMF_ALLOCATOR_CLASS::Delete(
    UMF_MESSAGE msg)
{
    assert(msg);

    // add to free list
    msg->SetNext(freeList);
    freeList = msg;

    // track and log
    numFree++;
    T2("\t\tumf_allocator: Delete(): free list size = " << numFree);
}
