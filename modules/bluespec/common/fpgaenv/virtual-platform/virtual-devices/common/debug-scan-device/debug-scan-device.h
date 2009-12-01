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

#ifndef _DEBUG_SCAN_DEVICE_
#define _DEBUG_SCAN_DEVICE_

#include <bitset>

#include "platforms-module.h"
#include "asim/provides/rrr.h"

#include "asim/dict/DEBUG_SCAN.h"
#include "asim/rrr/client_stub_DEBUG_SCAN.h"

//
// Manage debug scan chain coming from the hardware.
//

#define DEBUG_SCAN_MAX_MSG_SIZE 1024

typedef class DEBUG_SCAN_DEVICE_SERVER_CLASS* DEBUG_SCAN_DEVICE_SERVER;
typedef class DEBUG_SCAN_DEVICE_SERVER_CLASS* DEBUG_SCAN_SERVER;

class DEBUG_SCAN_DEVICE_SERVER_CLASS: public RRR_SERVER_CLASS,
                               public PLATFORMS_MODULE_CLASS
{
  private:
    // self-instantiation
    static DEBUG_SCAN_DEVICE_SERVER_CLASS instance;

    // stubs
    RRR_SERVER_STUB serverStub;
    DEBUG_SCAN_CLIENT_STUB clientStub;

    // Internal display method
    void DisplayMsg();

    UINT8 msg[DEBUG_SCAN_MAX_MSG_SIZE];
    int msgIdx;
    UINT8 msgID;

  public:
    DEBUG_SCAN_DEVICE_SERVER_CLASS();
    ~DEBUG_SCAN_DEVICE_SERVER_CLASS();

    // static methods
    static DEBUG_SCAN_DEVICE_SERVER GetInstance() { return &instance; }

    // required RRR methods
    void Init(PLATFORMS_MODULE);
    void Uninit();
    void Cleanup();

    // Method to tell the hardware to dump state.
    void Scan();

    // RRR service methods
    void  Send(UINT32 id, UINT8 value);
};

// server stub
#include "asim/rrr/server_stub_DEBUG_SCAN.h"

// all functionalities of the debug scan are completely implemented
// by the DEBUG_SCAN_DEVICE_SERVER class
typedef DEBUG_SCAN_DEVICE_SERVER_CLASS DEBUG_SCAN_DEVICE_CLASS;

#endif
