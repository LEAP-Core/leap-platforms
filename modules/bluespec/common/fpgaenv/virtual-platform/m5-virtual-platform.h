/*****************************************************************************
 * m5-virtual-platform.h
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
 * @file m5-virtual-platform.h
 * @author Michael Adler
 * @brief Virtual platform interface to m5 simulator
 */

#ifndef __M5_VIRTUAL_PLATFORM_h__
#define __M5_VIRTUAL_PLATFORM_h__

#include "sim/m5_main.hh"

typedef class VIRTUAL_PLATFORM_CLASS *VIRTUAL_PLATFORM;

class VIRTUAL_PLATFORM_CLASS
{
  public:
    VIRTUAL_PLATFORM_CLASS(int argc, char *argv[])
    {
        m5_main(argc, argv);
    };

    ~VIRTUAL_PLATFORM_CLASS() {};
};

#endif // __M5_VIRTUAL_PLATFORM_h__
