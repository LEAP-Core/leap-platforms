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

#ifndef __PHYSICAL_CHANNEL__
#define __PHYSICAL_CHANNEL__

#include "awb/provides/umf.h"
// tbb should really not be included here.  This should be viewed as a
// temporary consideration until a better interface is agreed upon.
#include "tbb/concurrent_queue.h"
#include "awb/provides/physical_platform_utils.h"
 
typedef class PHYSICAL_CHANNEL_CLASS* PHYSICAL_CHANNEL;
class PHYSICAL_CHANNEL_CLASS: public PLATFORMS_MODULE_CLASS
{

  public: 
    PHYSICAL_CHANNEL_CLASS(PLATFORMS_MODULE p);  
    ~PHYSICAL_CHANNEL_CLASS();  
    virtual UMF_MESSAGE Read() = 0;             // blocking read
    virtual UMF_MESSAGE TryRead() = 0;          // non-blocking read        
    virtual void        Write(UMF_MESSAGE) = 0; // write                           
    virtual class tbb::concurrent_bounded_queue<UMF_MESSAGE> *GetWriteQ() = 0; 
    virtual void SetUMFFactory(UMF_FACTORY factoryInit) = 0;
    virtual void RegisterLogicalDeviceName(string name) = 0;
};

#endif 
