/*****************************************************************************
 * umf-allocator.h
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
 * @file umf-allocator.h
 * @author Angshuman Parashar
 * @brief UMF Allocator interface
 */

#ifndef __UMF_ALLOCATOR__
#define __UMF_ALLOCATOR__

#include <iostream>
#include <pthread.h>

#include "asim/syntax.h"
#include "asim/mesg.h"
#include "asim/trace.h"

#include "asim/provides/umf.h"
#include "platforms-module.h"

using namespace std;

#define UMF_POOL_SIZE 32

// ================ UMF Allocator ================

typedef class UMF_ALLOCATOR_CLASS* UMF_ALLOCATOR;
class UMF_ALLOCATOR_CLASS: public PLATFORMS_MODULE_CLASS,
                           public TRACEABLE_CLASS
{
  private:
    // self-instantiation
    static UMF_ALLOCATOR_CLASS instance;

    // pool of UMF objects
    UMF_MESSAGE pool;

    // free list
    UMF_MESSAGE freeList;
    int         numFree;

    // lock
    pthread_mutex_t lock;

  public:
    // constructors and destructor
    UMF_ALLOCATOR_CLASS();
    ~UMF_ALLOCATOR_CLASS();

    void Init(PLATFORMS_MODULE p);

    // allocation and de-allocation
    UMF_MESSAGE New();
    void        Delete(UMF_MESSAGE msg);

    // access to static instance
    static UMF_ALLOCATOR GetInstance() { return &instance; }
};

#endif
