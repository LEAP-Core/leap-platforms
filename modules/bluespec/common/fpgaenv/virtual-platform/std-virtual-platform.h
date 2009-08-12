/*****************************************************************************
 * std-virtual-platform.h
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
 * @file std-virtual-platform.h
 * @author Michael Adler
 * @brief Standard virtual platform interface
 */

#ifndef __STD_VIRTUAL_PLATFORM_h__
#define __STD_VIRTUAL_PLATFORM_h__

#include <pthread.h>

#include "asim/provides/low_level_platform_interface.h"
#include "asim/provides/virtual_devices.h"

typedef class VIRTUAL_PLATFORM_CLASS *VIRTUAL_PLATFORM;

class VIRTUAL_PLATFORM_CLASS
{
  public:
    LLPI llpint;
    VIRTUAL_DEVICES virtualDevices;
    VIRTUAL_PLATFORM_CLASS();
    ~VIRTUAL_PLATFORM_CLASS();
    void Init();
};

#endif // __STD_VIRTUAL_PLATFORM_h__
