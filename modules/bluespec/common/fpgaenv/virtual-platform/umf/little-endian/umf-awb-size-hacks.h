//
// Copyright (C) 2010 Intel Corporation
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

//
// THIS FILE IS INCLUDED BY RRR FILES.  IT MAY HAVE ONLY MACROS!
//

// Hack for converting a bit size to an integer type
#define BITS_TO_INT(x) CONCAT_INT(x)
#define BITS_TO_UINT(x) CONCAT_UINT(x)

#define CONCAT_INT(x) INT##x
#define CONCAT_UINT(x) UINT##x
