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
        m = (UMF_MESSAGE)  memset(malloc(sizeof(UMF_MESSAGE_CLASS)), 0, sizeof(UMF_MESSAGE_CLASS));
        VERIFYX(m != NULL);
        m->setAllocator(this);
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
