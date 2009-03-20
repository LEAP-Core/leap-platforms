//
// Copyright (C) 2009 Intel Corporation
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

import Vector::*;

//
// This is a general interface to a multi-cycle memory.  By making it common we
// hope that code can switch between different memories changing only the
// call to a module constructor.
//

interface MEMORY_IFC#(type t_ADDR, type t_DATA);
    method Action readReq(t_ADDR addr);
    method ActionValue#(t_DATA) readRsp();

    method Action write(t_ADDR addr, t_DATA val);
endinterface


//
// Memory with one writer and multiple readers.
//

// Single reader interface
interface MEMORY_READER_IFC#(type t_ADDR, type t_DATA);
    method Action readReq(t_ADDR addr);
    method ActionValue#(t_DATA) readRsp();
endinterface

interface MEMORY_MULTI_READ_IFC#(numeric type nReaders, type t_ADDR, type t_DATA);
    interface Vector#(nReaders, MEMORY_READER_IFC#(t_ADDR, t_DATA)) readPorts;

    method Action write(t_ADDR addr, t_DATA val);
endinterface
