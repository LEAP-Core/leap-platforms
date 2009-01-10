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

#ifndef __PHYSICAL_PLATFORM_DEBUGGER__
#define __PHYSICAL_PLATFORM_DEBUGGER__

#include "asim/provides/physical_platform.h"

// ============================================
//       Null Physical Platform Debugger              
// ============================================

class PHYSICAL_PLATFORM_DEBUGGER_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:

  public:

    PHYSICAL_PLATFORM_DEBUGGER_CLASS(PLATFORMS_MODULE, PHYSICAL_DEVICES);
    ~PHYSICAL_PLATFORM_DEBUGGER_CLASS();

    void Monitor();
};

#endif
