//
// Copyright (C) 2008 Intel Corporation
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

#ifndef __PHYSICAL_CHANNEL__
#define __PHYSICAL_CHANNEL__

#include <pthread.h>

#include "asim/provides/umf.h"
#include "asim/provides/pci_express_device.h"
#include "asim/provides/physical_platform.h"

// ============================================
//               Physical Channel              
// ============================================

class PHYSICAL_CHANNEL_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:

    // links to useful physical devices
    PCIE_DEVICE pciExpressDevice;
    
    // physical channel state
    CSR_INDEX f2hHead;
    CSR_INDEX f2hTailCache;
    CSR_INDEX h2fHeadCache;
    CSR_INDEX h2fTail;
    
    // incomplete incoming read message
    UMF_MESSAGE incomingMessage;
    
    // instruction ID
    CSR_DATA iid;
    
    // internal methods
    void     readCSR();
    CSR_DATA genIID();
    
    pthread_mutex_t channelLock;

  public:

    PHYSICAL_CHANNEL_CLASS(PLATFORMS_MODULE, PHYSICAL_DEVICES);
    ~PHYSICAL_CHANNEL_CLASS();
    
    UMF_MESSAGE Read();             // blocking read
    UMF_MESSAGE TryRead();          // non-blocking read
    void        Write(UMF_MESSAGE); // write
};

#endif
