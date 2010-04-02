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

//
// NULL local memory.
//

`include "asim/provides/physical_platform.bsh"
`include "asim/provides/fpga_components.bsh"


typedef `LOCAL_MEM_ADDR_BITS LOCAL_MEM_ADDR_SZ;

module mkLocalMem#(PHYSICAL_DRIVERS drivers)
    // interface:
    (LOCAL_MEM);

    method Action readWordReq(LOCAL_MEM_ADDR addr);
        noAction;
    endmethod

    method ActionValue#(LOCAL_MEM_WORD) readWordRsp();
        return ?;
    endmethod


    method Action readLineReq(LOCAL_MEM_ADDR addr);
        noAction;
    endmethod

    method ActionValue#(LOCAL_MEM_LINE) readLineRsp();
        return ?;
    endmethod


    method Action writeWord(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data);
        noAction;
    endmethod

    method Action writeLine(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data);
        noAction;
    endmethod

    method Action writeWordMasked(LOCAL_MEM_ADDR addr, LOCAL_MEM_WORD data, LOCAL_MEM_WORD_MASK mask);
        noAction;
    endmethod

    method Action writeLineMasked(LOCAL_MEM_ADDR addr, LOCAL_MEM_LINE data, LOCAL_MEM_LINE_MASK mask);
        noAction;
    endmethod
endmodule
