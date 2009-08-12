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
 * @file std-virtual-platform.cpp
 * @author Michael Adler
 * @brief Standard virtual platform interface
 */

#include "asim/provides/virtual_platform.h"

VIRTUAL_PLATFORM_CLASS::VIRTUAL_PLATFORM_CLASS() :
    llpint( new LLPI_CLASS() ), 
    virtualDevices( new VIRTUAL_DEVICES_CLASS(llpint) )
{
    return;
}

VIRTUAL_PLATFORM_CLASS::~VIRTUAL_PLATFORM_CLASS()
{
    delete virtualDevices;
    delete llpint;
}

void
VIRTUAL_PLATFORM_CLASS::Init()
{
    llpint->Init();
    virtualDevices->Init();
}
