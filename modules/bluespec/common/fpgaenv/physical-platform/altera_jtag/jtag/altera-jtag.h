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

#ifndef __PHYSICAL_PLATFORM__
#define __PHYSICAL_PLATFORM__

#include "platforms-module.h"
#include "awb/provides/physical_channel.h"
#include "awb/provides/physical_platform_utils.h"
#include "awb/provides/physical_platform_defs.h"
#include "awb/provides/jtag_device.h"

typedef class PHYSICAL_DEVICES_CLASS* PHYSICAL_DEVICES;
class PHYSICAL_DEVICES_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:

    JTAG_PHYSICAL_CHANNEL_CLASS jtagPipeDevice;

  public:

    // constructor-destructor
    PHYSICAL_DEVICES_CLASS(PLATFORMS_MODULE);
    ~PHYSICAL_DEVICES_CLASS();

    // accessors to individual devices
    PHYSICAL_CHANNEL GetLegacyPhysicalChannel() 
    { 
        jtagPipeDevice.RegisterLogicalDeviceName(FPGA_PLATFORM_NAME);
        return &jtagPipeDevice;
    }

};

#endif
