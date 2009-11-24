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
#include "asim/freelist.h"

#include "asim/provides/umf.h"
#include "platforms-module.h"

using namespace std;


// ================ UMF Allocator ================

typedef class UMF_ALLOCATOR_CLASS* UMF_ALLOCATOR;
class UMF_ALLOCATOR_CLASS: public PLATFORMS_MODULE_CLASS,
                           public TRACEABLE_CLASS
{
  private:
    // self-instantiation
    static UMF_ALLOCATOR_CLASS instance;

    // Lock-free, thread safe, list of free UMF objects
    ASIM_FREE_LIST_CLASS<UMF_MESSAGE_CLASS> freeList;

  public:
    // constructors and destructor
    UMF_ALLOCATOR_CLASS();
    ~UMF_ALLOCATOR_CLASS();

    void Init(PLATFORMS_MODULE p);

    // allocation and de-allocation
    inline UMF_MESSAGE New();
    inline void        Delete(UMF_MESSAGE msg);

    // access to static instance
    static UMF_ALLOCATOR GetInstance() { return &instance; }
};


// allocate a new message
inline UMF_MESSAGE
UMF_ALLOCATOR_CLASS::New()
{
    UMF_MESSAGE m = freeList.Pop();
    if (m == NULL)
    {
        m = (UMF_MESSAGE) malloc(sizeof(UMF_MESSAGE_CLASS));
        VERIFYX(m != NULL);
    }

    return m;
}

// de-allocate a message
inline void
UMF_ALLOCATOR_CLASS::Delete(
    UMF_MESSAGE msg)
{
    freeList.Push(msg);
}

#endif
