/*****************************************************************************
 * umf-little-endian.cpp
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
 * @file umf-little-endian.cpp
 * @author Angshuman Parashar
 * @brief UMF implementation
 */

//
// Little-endian UMF
//

#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <iomanip>

#include "asim/provides/umf.h"

using namespace std;

// constructors
UMF_MESSAGE_CLASS::UMF_MESSAGE_CLASS()
{
    Clear();
}

// destructor
UMF_MESSAGE_CLASS::~UMF_MESSAGE_CLASS()
{
}

// init
void
UMF_MESSAGE_CLASS::Init(
    PLATFORMS_MODULE p)
{
    parent = p;
}

// clear all message data
inline void
UMF_MESSAGE_CLASS::Clear()
{
    length     = 0;
    readIndex  = 0;
    writeIndex = 0;
}

// allocate a new message: pipe through to the allocator
static void *
UMF_MESSAGE_CLASS::operator new(size_t size)
{
    ASSERTX(size == sizeof(UMF_MESSAGE_CLASS));

    // ask allocator to give us a new message
    UMF_MESSAGE retval = UMF_ALLOCATOR_CLASS::GetInstance()->New();

    // optional: initialize
    retval->Clear();

    return retval;
}

// de-allocate this message: pipe through to the allocator
static void
UMF_MESSAGE_CLASS::operator delete(void *obj)
{
    // ask allocator to de-allocate me
    UMF_ALLOCATOR_CLASS::GetInstance()->Delete((UMF_MESSAGE)obj);
}


// print message to an output stream
void
UMF_MESSAGE_CLASS::Print(
    ostream &out)
{
    out << "channelID: " << channelID << endl;
    out << "serviceID: " << serviceID << endl;
    out << "methodID : " << methodID  << endl;
    out << "length   : " << length    << endl;
    out << "data     : ";

    for (int i = 0; i < length; i++)
    {
        out << std::setfill('0');
        out << hex << std::setw(2) << UINT32(message[i]) << " ";
    }
    out << dec << endl;
}
