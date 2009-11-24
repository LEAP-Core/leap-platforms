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

#define UMF_POOL_SIZE 32

// self-instantiate
UMF_ALLOCATOR_CLASS UMF_ALLOCATOR_CLASS::instance;

// constructor
UMF_ALLOCATOR_CLASS::UMF_ALLOCATOR_CLASS()
{
    SetTraceableName("umf_allocator");

    // Preallocate some entries for the pool, hoping they will be contiguous
    for (int i = 0; i < UMF_POOL_SIZE; i++)
    {
        UMF_MESSAGE m = (UMF_MESSAGE) malloc(sizeof(UMF_MESSAGE_CLASS));
        freeList.Push(m);
    }
}

// destructor
UMF_ALLOCATOR_CLASS::~UMF_ALLOCATOR_CLASS()
{
    // Free what we can
    while (UMF_MESSAGE msg = freeList.Pop())
    {
        free((void*) msg);
    }
}

// init
void
UMF_ALLOCATOR_CLASS::Init(
    PLATFORMS_MODULE p)
{
    parent = p;
}
